class QuestionController < ApplicationController
  before_filter :get_profile

  def new
  end

  def answer
    # Reset the session data
    session[:quantity] = nil
    session[:terms] = nil
    session[:categories] = nil
    # Save this search in the database
    search = Search.find_by_string(params[:q]) || Search.new(:string => params[:q])
    search.count += 1
    search.save!
    # Get the query parameters out
    query = params[:q].split
    @quantities = Quantity.parse(params[:q])
    @quantity = @quantities.first
    @quantity = nil if @quantity.unit.nil?
    unit_terms = @quantities.map {|q| [q.unit.name, q.unit.pluralized_name, q.unit.symbol, q.unit.label] }.flatten
    # Then run term extraction for interesting words
    @terms = TermExtract.extract(query.select{|x| x.is_a? String}.join(' '), :min_occurance => 1).map{|x| x[0]}
    ignore = [
      "emissions",
      "impact"
    ] + unit_terms
    @terms.delete_if {|x| ignore.include? x }
    # Find some AMEE categories that look relevant
    # Create new search for cat results
    # AMEE::Search has an implicit map here, so we get back a list of wikinames
    unless @quantity.nil? || @terms.empty?
      @categories = AMEE::Search.new( AMEE::Rails.connection, :q => thesaurus_expand(@terms.join(" ")), :types=>'DC', :matrix => 'itemDefinition;path', :excTags=>'ecoinvent' ) do |y|
        y.result.meta.wikiname
      end
      # Everything is stored in the session under a unique ID, as we'll need to come back to it later.
      # The unique ID is used to avoid clashes when multiple queries happen in the same session
      @query_id = UUIDTools::UUID.timestamp_create
      session.clear
      session[:quantity] = @quantity
      session[:terms] = @terms
      session[:categories] = @categories.to_a
      @message = thinking_message
    end
  rescue NoMethodError => ex
    # Incuded to catch quantify parse errors
    nil
  end

  def detailed_answer
    @message = thinking_message
    @terms = session[:terms]
    @quantity = session[:quantity]
    @profile = AMEE::Profile::ProfileList.new(AMEE::Rails.connection).first || AMEE::Profile::Profile.create(AMEE::Rails.connection)
    
    # Check inputs are valid. Skip if not. We shouldn't really get here, but be defensive just in case.
    return if session[:categories].nil? || session[:categories].empty? || @terms.nil? || @quantity.nil?
    
    # Get category, filter out bad ones
    @category = begin
      AMEE::Data::Category.find_by_wikiname(AMEE::Rails.connection, session[:categories].delete_at(0), :matrix => 'itemDefinition;path')
    rescue AMEE::PermissionDenied
      nil
    end

    @category = nil if (@category.nil? ||
                        @category.meta.wikiname.blank? || 
                        @category.meta.deprecated?|| 
                        @category.item_definition.nil? || 
                        @category.meta.tags.include?("deprecated"))

    # Check IVD check that inputs are compatible with the units you've asked for
    if @category
      Rails.logger.info ('finding IVD')
      ivds = @category.item_definition.item_value_definition_list.sort{|a,b| a.path<=>b.path}
      ivds = ivds.select{|x| x.profile? && x.versions.any?{|y| y=~/2/}}
      @ivd = ivds.find{|x| x.unit && (@quantity.unit.label == x.unit || @quantity.unit.alternatives_by_label.include?(x.unit)) }
      Rails.logger.info ('found IVD') if @ivd
    end

    # Search for a data item
    if @category
      @item = AMEE::Search::WithinCategory.new( AMEE::Rails.connection, :label => thesaurus_expand(@terms.join(" ")), :wikiname=>@category.meta.wikiname, :resultMax => 1, :matrix => 'label').try(:first).try(:result)
      @item = @category.data_items(:resultMax => 10, :matrix => 'label').find{|x| x.label != x.uid } if @item.nil?
    end

    # Do the calculation
    if @category && @item && @ivd

      # create our profile item then get result back
      @pi = AMEE::Profile::Item.create_without_category(AMEE::Rails.connection,
                                                       "/profiles/#{@profile.uid}#{@category.path}",
                                                       @item.uid,
                                                       {
                                                         @ivd.path.to_sym => @quantity.value,
                                                         :"#{@ivd.path}Unit" => @quantity.unit.label,
                                                         :name => UUIDTools::UUID.timestamp_create
      })
      session[:got_result] = true
    end
  end
  
  protected
  
  def thinking_message
    [
      "Reticulating splines",
      "Peering through the intertubes",
      "Asking the cats",
      "Commencing guru meditation",
      "Charging flux capacitor",
      "Reversing the polarity of the neutron flow",
      "Casting runes",
      "Deploying ninjas",
      "Collapsing waveforms"
    ].shuffle.first
  end
  
  def get_profile
    @profile = (session[:profile] ||= AMEE::Profile::Profile.create(AMEE::Rails.connection))
  end  
  
  def thesaurus_expand(query,inflect=true)
    terms=CSV::parse_line(query,' ') # so that quoted strings aren't tokenized
    finalterms=[]
    terms.each do |term|
      next unless term
      logicsymbol=term.slice(0,1)
      if (logicsymbol=~/[\+\-]/)
        lterm=term.slice(1,term.length)
      else
        lterm=term.to_s
        logicsymbol=nil
      end
      expanded=[lterm]
      THESAURUS.each do |synonym_list|
        # assume synonym lists disjoint.
        # otherwise will end up with the original term multiple times
        if synonym_list.include?(lterm)
          expanded.concat synonym_list-[lterm]
        end
      end
      aexpanded=expanded.clone
      aexpanded.each do |e|
        expanded<<e.pluralize unless e.pluralize==e if inflect
        expanded<<e.singularize unless e.singularize==e if inflect
      end
      finalterms.push(restorelogic(logicsymbol,expanded))
    end
    finalterms.join(' ')
  end
  
  def restorelogic(operator,terms)
      return terms.join(" ") if operator==nil
      return "+(#{terms.join(" ")})" if operator=="+"&&terms.length>1
      return "+#{terms.first}" if operator=="+"
      return "-#{terms.join(" -")}" if operator=="-"
  end

end