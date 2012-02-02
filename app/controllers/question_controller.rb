require 'query_parser'
require 'thesaurus'

class QuestionController < ApplicationController

  include QueryParser
  include Thesaurus

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
    
    # Parse query
    @quantities, @terms = parse_query(params[:q])

    # Find some AMEE categories that look relevant
    # Create new search for cat results
    # AMEE::Search has an implicit map here, so we get back a list of wikinames
    @categories = []
    @quantity = @quantities.first
    unless @quantity.nil? || @terms.empty?
      @categories = AMEE::Search.new( AMEE::Rails.connection, :q => thesaurus_expand(@terms.join(" ")), :types=>'DC', :matrix => 'itemDefinition;path', :excTags=>'ecoinvent', :resultMax => 30 ) do |y|
        y.result.meta.wikiname
      end
      # Everything is stored in the session under a unique ID, as we'll need to come back to it later.
      # The unique ID is used to avoid clashes when multiple queries happen in the same session
      @query_id = UUIDTools::UUID.timestamp_create
      session.clear
      session[:quantities] = @quantities = [@quantity]
      session[:terms] = @terms
      session[:categories] = @categories = @categories.to_a
      @message = thinking_message
      respond_to do |format|
        format.html
        format.json
      end
    end
  end

  def detailed_answer
    # Split URL paramters if present
    if params[:quantities]
      params[:quantities] = params[:quantities].split(',').map{|x| Quantity.parse(x)}.flatten
    end
    params[:terms] = params[:terms].split(',') if params[:terms]
    
    # Get parameters
    @message = thinking_message
    @terms = params[:terms] || session[:terms]
    @quantity = (params[:quantities] ? params[:quantities].first : session[:quantities].first)
    
    # Check inputs are valid. Skip if not. We shouldn't really get here, but be defensive just in case.
    return if @terms.nil? || @quantity.nil?

    @category_name = params[:category]
    if @category_name.nil?
      return if session[:categories].nil? || session[:categories].empty?
      @category_name = session[:categories].delete_at(0)
    end
        
    # Get category, filter out bad ones
    @category = begin
      AMEE::Data::Category.find_by_wikiname(AMEE::Rails.connection, @category_name, :matrix => 'itemDefinition;path')
    rescue AMEE::PermissionDenied
      @private = true if params[:private] == true
      nil
    end

    @category = nil if (@category.nil? ||
                        @category.meta.wikiname.blank? || 
                        @category.meta.deprecated?|| 
                        @category.item_definition.nil? || 
                        @category.meta.tags.include?("deprecated"))

    # Check IVD check that inputs are compatible with the units you've asked for
    if @category
      ivds = @category.item_definition.item_value_definition_list.sort{|a,b| a.path<=>b.path}
      ivds = ivds.select{|x| x.profile? && x.versions.any?{|y| y=~/2/}}
      @ivd = ivds.find{|x| (@quantity.unit.label == x.unit.to_s) || @quantity.unit.alternatives_by_label.include?(x.unit.to_s) }
    end

    # Search for a data item
    if @category
      @item = AMEE::Search::WithinCategory.new( AMEE::Rails.connection, :label => thesaurus_expand(@terms.join(" ")), :wikiname=>@category.meta.wikiname, :resultMax => 1, :matrix => 'label').try(:first).try(:result)
      @item = @category.data_items(:resultMax => 10, :matrix => 'label').find{|x| x.label != x.uid } if @item.nil?
    end

    # Do the calculation
    if @category && @item && @ivd
      begin
        opts = {
          @ivd.path.to_sym => @quantity.value
        }
        opts[:"#{@ivd.path}Unit"] = @quantity.unit.label unless @quantity.unit.label.blank?
        @pi = AMEE::Data::Item.get(AMEE::Rails.connection,
                                   "/data#{@category.path}/#{@item.uid}",
                                   opts)
        session[:got_result] = true
      rescue AMEE::BadRequest => ex
        # Something went wrong; notify about the result but let the user carry on
        notify_airbrake(ex)
        @category = nil
      end
    end
    
    @amount = @pi.amounts.find{|x| x[:default] == true} if @pi
    
    respond_to do |format|
      format.js
      format.json
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
  
end