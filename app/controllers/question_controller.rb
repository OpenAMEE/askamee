class QuestionController < ApplicationController
  before_filter :get_profile

  def new
  end

  def answer
    # Get the query parameters out
    query = params[:q].split
    # First, extract anything that Quantify can understand
    content = query.map do |str|
      begin
        Quantity.parse str
      rescue Quantify::Exceptions::QuantityParseError
        str
      end
    end
    @quantity = content.find{|x| x.is_a? Quantity}
    # Then run term extraction for interesting words
    @terms = TermExtract.extract(content.select{|x| x.is_a? String}.join(' '), :min_occurance => 1).map{|x| x[0]}
    ignore = [
      "emissions",
      "impact"
    ]
    @terms.delete_if {|x| ignore.include? x }
    # Find some AMEE categories that look relevant
    # Create new search for cat results
    # AMEE::Search has an implicit map here, so we get back a list of wikinames
    @categories = AMEE::Search.new( AMEE::Rails.connection, :q => @terms.join(" "), :types=>'DC', :resultMax => 10, :matrix => 'itemDefinition;path', :excTags=>'ecoinvent' ) do |y|
      y.result.meta.wikiname
    end
    # Everything is stored in the session under a unique ID, as we'll need to come back to it later.
    # The unique ID is used to avoid clashes when multiple queries happen in the same session
    @query_id = UUIDTools::UUID.timestamp_create
    session.clear
    session[:quantity] = @quantity.to_s
    session[:terms] = @terms
    session[:categories] = @categories.to_a
    @message = thinking_message
  end

  def detailed_answer
    @terms = session[:terms]
    @quantity = Quantity.parse(session[:quantity])
    @profile = AMEE::Profile::ProfileList.new(AMEE::Rails.connection).first || AMEE::Profile::Profile.create(AMEE::Rails.connection)

    # Get category, filter out bad ones
    @category = AMEE::Data::Category.find_by_wikiname(AMEE::Rails.connection, session[:categories].delete_at(0), :matrix => 'itemDefinition;path')

    passing = @category.meta.wikiname &&
      !@category.meta.deprecated? &&
      @category.item_definition

    # Check IVD check that inputs are compatible with the units you've asked for
    if passing
      ivds = @category.item_definition.item_value_definition_list.sort{|a,b| a.path<=>b.path}
      ivds = ivds.select{|x| x.profile? && x.versions.any?{|y| y=~/2/}}
      @ivd = ivds.find{|x| x.unit && (@quantity.unit.label == x.unit || @quantity.unit.alternatives_by_label.include?(x.unit)) }
    end


    # Get 1st data item (TODO make it get the _best_ one)
    @item = passing ? @category.data_items(:resultMax => 1, :matrix => 'label').first : nil

    # Do the calculation
    if passing && @item && @ivd

      # create our profile item then get result back
      @pi = AMEE::Profile::Item.create_without_category(AMEE::Rails.connection,
                                                       "/profiles/#{@profile.uid}#{@category.path}",
                                                       @item.uid,
                                                       {
                                                         @ivd.path.to_sym => @quantity.value,
                                                         :"#{@ivd.path}Unit" => @quantity.unit.label,
                                                         :name => UUIDTools::UUID.timestamp_create
      })
    end
    @message = thinking_message
  end
  
  protected
  
  def thinking_message
    [
      "Reticulating splines",
      "Peering through the intertubes",
      "Asking the cats",
      "Enabling guru meditation",
      "Charging flux capacitor",
      "Reversing the polarity of the neutron flow",
    ].shuffle.first
  end
  
  def get_profile
    @profile = (session[:profile] ||= AMEE::Profile::Profile.create(AMEE::Rails.connection))
  end  
  
end