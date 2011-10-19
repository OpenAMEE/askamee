class QuestionController < ApplicationController
  def new
  end

  def answer
    query = params[:question][:q].split
    content = query.map do |str|
      begin
        Quantity.parse str
      rescue Quantify::Exceptions::QuantityParseError
        str
      end
    end

    @quantity = content.find{|x| x.is_a? Quantity}
    session["quantity"] = @quantity

    @terms = TermExtract.extract(content.select{|x| x.is_a? String}.join(' '), :min_occurance => 1).map{|x| x[0]}
    ignore = [
      "emissions",
      "impact"
    ]
    @terms.delete_if {|x| ignore.include? x }

    # Find some AMEE categories that look relevant
    @profile = AMEE::Profile::ProfileList.new(AMEE::Rails.connection).first || AMEE::Profile::Profile.create(AMEE::Rails.connection)
    # Create new search for cat results
    # implicit map here
    @categories = AMEE::Search.new( AMEE::Rails.connection, :q => @terms.join(" "), :types=>'DC', :resultMax => 10, :matrix => 'itemDefinition;path', :excTags=>'ecoinvent' ) do |y|

      #  TO MAKE THIS AN AJAX VERSION:
      #  1) get search back
      #  2) then load `y.result.meta.wikiname` into the session
      #  3) pop the most recent of the stack - AMEE::Data::Category.find_by_wikiname(:matrix => 'item_definition' )
      #  4) run sequence below and add to page
      y.result.meta.wikiname
    end
    session['cats'] = @categories.to_a
  end

  def fetch_reading(category=nil)
    # binding.pry
    @session_content = session["content"]
    @quantity = session["quantity"]
    # Find some AMEE categories that look relevant
    @profile = AMEE::Profile::ProfileList.new(AMEE::Rails.connection).first || AMEE::Profile::Profile.create(AMEE::Rails.connection)

    # put this in a separate action
    # binding.pry
       # Get category, filter out bad ones
       @category = AMEE::Data::Category.find_by_wikiname(AMEE::Rails.connection, params[:category], :matrix => 'itemDefinition;path')
       
       passing = @category.meta.wikiname &&
         !@category.meta.deprecated? &&
         @category.item_definition

       # Check IVD check that inputs are compatible with the units you've asked for
       if passing
         ivds = @category.item_definition.item_value_definition_list.sort{|a,b| a.path<=>b.path}
         ivds = ivds.select{|x| x.profile? && x.versions.any?{|y| y=~/2/}}
         ivd = ivds.find{|x| x.unit && (@quantity.unit.label == x.unit || @quantity.unit.alternatives_by_label.include?(x.unit)) }
       end


       # Get 1st data item (TODO make it get the _best_ one)
       item = passing ? @category.data_items(:resultMax => 1, :matrix => 'label').first : nil

       # Do the calculation
       pi = nil
       if passing && item && ivd

         # create our profile item then get result back
         pi = AMEE::Profile::Item.create_without_category(AMEE::Rails.connection,
                                                          "/profiles/#{@profile.uid}#{@category.path}",
                                                          item.uid,
                                                          {
                                                            ivd.path.to_sym => @quantity.value,
                                                            :"#{ivd.path}Unit" => @quantity.unit.label,
                                                            :name => UUIDTools::UUID.timestamp_create
         })
       end
       # Return results

       if passing && item && ivd && pi
         [@category, item, ivd, pi]
       else
         nil
       end




  end
end