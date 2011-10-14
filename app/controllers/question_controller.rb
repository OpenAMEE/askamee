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
  end

end
