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
    @terms = TermExtract.extract(content.select{|x| x.is_a? String}.join(' '), :min_occurance => 1).map{|x| x[0]}
    ignore = [
      "emissions",
      "impact"
    ]
    @terms.delete_if {|x| ignore.include? x }
    
    # Find some AMEE categories that look relevant
    @profile = AMEE::Profile::ProfileList.new(AMEE::Rails.connection).first || AMEE::Profile::Profile.create(AMEE::Rails.connection)    
    @categories = AMEE::Search.new(AMEE::Rails.connection, :q => @terms.join(" "), :types=>'DC', :resultMax => 10, :matrix => 'itemDefinition;path', :excTags=>'ecoinvent') do |y|
      # Get category
      cat = y.result
      passing = cat.meta.wikiname &&
        !cat.meta.deprecated? && 
        cat.item_definition
      # Check IVD
      if passing
        ivds = cat.item_definition.item_value_definition_list.sort{|a,b| a.path<=>b.path}
        ivds = ivds.select{|x| x.profile? && x.versions.any?{|y| y=~/2/}}
        ivd = ivds.find{|x| x.unit && (@quantity.unit.label == x.unit || @quantity.unit.alternatives_by_label.include?(x.unit)) } 
      end
      # Get data item
      item = passing ? cat.data_items(:resultMax => 1, :matrix => 'label').first : nil
      # Do the calculation
      pi = nil
      if passing && item && ivd
        pi = AMEE::Profile::Item.create_without_category(AMEE::Rails.connection,
                                                         "/profiles/#{@profile.uid}#{cat.path}",
                                                         item.uid,
                                                         {
                                                           ivd.path.to_sym => @quantity.value,
                                                           :"#{ivd.path}Unit" => @quantity.unit.label,
                                                           :name => UUIDTools::UUID.timestamp_create
                                                         })
      end
      # Return results
      if passing && item && ivd && pi
        [cat, item, ivd, pi]
      else
        nil
      end
    end

  end

end
