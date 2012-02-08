require 'query_parser'
require 'thesaurus'
require 'discover'

class QuestionController < ApplicationController

  include QueryParser
  include Thesaurus
  include AMEE::Discover

  caches_action :new
  caches_action :answer, :cache_path => Proc.new {|c| c.request.url }
  caches_action :detailed_answer, :cache_path => Proc.new {|c| c.request.url }

  def new
  end

  def answer
    
    # Save this search in the database
    search = Search.find_by_string(params[:q]) || Search.new(:string => params[:q])
    search.count += 1
    search.save!
    
    # Parse query
    @quantities, @terms = parse_query(params[:q])

    # Find some AMEE categories that look relevant
    # AMEE::Search has an implicit map here, so we get back a list of wikinames
    @categories = []
    unless @quantities.empty? || @terms.empty?
      @categories = AMEE::Search.new( AMEE::Rails.connection, 
                                      :q => thesaurus_expand(@terms.join(" ")), 
                                      :types=>'DC', 
                                      :matrix => 'itemDefinition;path', 
                                      :excTags=>'ecoinvent,deprecated',
                                      :resultMax => 30) { |y|
        y.result.meta.wikiname && y.result.itemdef.present? ? y.result.meta.wikiname : nil
      }.to_a
    end
    
    # Render
    respond_to do |format|
      format.html {
        @message = thinking_message        
        # Allow two detailed response requests at a time
        @concurrency = 2
      }
      format.json
    end
    
  end

  def detailed_answer
    # Get parameters
    @terms = params[:terms].split(',') rescue []
    @quantities = params[:quantities].split(',').map{|x| Quantity.parse(x, :remainder => true)}.flatten.select{|x| !x.blank?}
    @category_name = params[:category]

    # Check inputs are valid. Skip if not. We shouldn't really get here, but be defensive just in case.
    return if @terms.empty? || @quantities.empty? || @category_name.nil?

    # Get category, filter out bad ones
    @category = begin
      AMEE::Data::Category.find_by_wikiname(AMEE::Rails.connection, @category_name, :matrix => 'itemDefinition;path')
    rescue AMEE::PermissionDenied
      @private = true if params[:private] == true
      nil
    end

    # Do the calculation
    if @category
      # Assign quantities to input parameters
      @inputs = assign_inputs(@category, @quantities)
      # As long as we have the right matching inputs...
      if @inputs.size == @quantities.size
        # Search for a data item
        @item = AMEE::Search::WithinCategory.new( AMEE::Rails.connection, :label => thesaurus_expand(@terms.join(" ")), :wikiname=>@category.meta.wikiname, :resultMax => 1, :matrix => 'label').try(:first).try(:result)
        @item = @category.data_items(:resultMax => 10, :matrix => 'label').find{|x| x.label != x.uid } if @item.nil?
        if @item
          begin
            # Do the calculation
            @pi = AMEE::Data::Item.get(AMEE::Rails.connection,
                                       "/data#{@category.path}/#{@item.uid}",
                                       create_amee_params(@inputs))
            @pi = nil if @pi.amounts.empty?
          rescue AMEE::BadRequest => ex
            # Something went wrong; notify about the result but let the user carry on
            notify_airbrake(ex)
          end
        end
      end
    end

    
    @amount = @pi.amounts.find{|x| x[:default] == true} if @pi
    
    @more_info_url = discover_url(@category, @item, @pi)
    
    respond_to do |format|
      format.js {
        @message = thinking_message
      }
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
  
  def assign_inputs(category, quantities)
    # get v2 profile ivds
    ivds = category.item_definition.item_value_definition_list.sort{|a,b| a.path<=>b.path}
    ivds = ivds.select{|x| x.profile? && x.versions.any?{|y| y=~/2/}}
    # Assign each quantity to a matching profile IVD
    inputs = {}
    quantities.each do |quantity|
      if quantity.is_a?(Quantity)
        # Find an ivd with the right dimensionality
        ivd = ivds.find{|x| (quantity.unit.label == x.unit.to_s) || quantity.unit.alternatives_by_label.include?(x.unit.to_s) }
        inputs[ivd] = quantity if ivd
      elsif quantity.start_with?("from:")
        inputs.merge! match_journey_start(category, ivds, quantity)
      elsif quantity.start_with?("to:")
        inputs.merge! match_journey_end(category, ivds, quantity)
      end
    end
    # Done
    inputs
  end

  def create_amee_params(inputs)
    amee_params = {}
    inputs.each_pair do |ivd, quantity|
      if quantity.is_a?(Quantity)
        # Create input parameters for value...
        amee_params[:"#{ivd.path}"] = quantity.value
        # ... and unit, if appropriate
        amee_params[:"#{ivd.path}Unit"] = quantity.unit.label unless quantity.unit.label.blank?
      else
        # Create input parameter for the string
        amee_params[:"#{ivd.path}"] = quantity
      end
    end
    amee_params
  end

  # This is a bit of a cheat - we hardcode categories that we know can represent start/end points
  def match_journey_start(category, ivds, quantity)
    case category.meta.wikiname
    when "Great_Circle_flight_methodology", "Specific_jet_aircraft", "Specific_turboprop_aircraft"
      {ivds.find{|x| x.path == 'IATACode1'} => quantity.split(':')[1]}
    when "Train_Route"
      {ivds.find{|x| x.path == 'station1'} => quantity.split(':')[1]}
    else
      {}
    end
  end
  def match_journey_end(category, ivds, quantity)
    case category.meta.wikiname
    when "Great_Circle_flight_methodology", "Specific_jet_aircraft", "Specific_turboprop_aircraft"
      {ivds.find{|x| x.path == 'IATACode2'} => quantity.split(':')[1]}
    when "Train_Route"
      {ivds.find{|x| x.path == 'station2'} => quantity.split(':')[1]}      
    else
      {}
    end
  end

end