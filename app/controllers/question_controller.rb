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
    @quantities = content.select{|x| x.is_a? Quantity}
    @terms = TermExtract.extract(content.select{|x| x.is_a? String}.join(' '), :min_occurance => 1).map{|x| x[0]}
    ignore = [
      "emissions",
      "impact"
    ]
    @terms.delete_if {|x| ignore.include? x }
    
    # Find some AMEE categories that look relevant
    @categories = AMEE::Search.new(AMEE::Rails.connection, :q => @terms.join(" "), :types=>'DC', :resultMax => 10, :matrix => 'itemDefinition', :excTags=>'ecoinvent') do |y|
      x = y.result
      passing = x.meta.wikiname &&
        !x.meta.deprecated? && 
        x.item_definition
      item = passing ? x.data_items(:resultMax => 1, :matrix => 'label').first : nil
      if passing && item
        [x, item]
      else
        nil
      end
    end
    
    
    #.find{|x| x.supports_auto_gallery? == true}
    #puts category.map {|x| x.has_item_definition?}
    
  end

end
