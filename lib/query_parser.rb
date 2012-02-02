module QueryParser
  
  # Takes a search string and parses it into a combination of inputs and search terms
  def parse_query(q)
    # Parse quantities first
    begin 
      quantities, terms = Quantity.parse(q, :remainder => true)
    rescue NoMethodError => ex
      # Incuded to catch quantify parse errors
      quantities = []
      terms = q
    end
    # Re-marshal terms into an array split on space
    terms = terms.map{|x| x.split(' ')}.flatten
    # Ignore common words
    ignore = [
      "emissions",
      "impact",
      "and",
      "of",
      "the",
      "a",
      "in"
    ]
    terms.delete_if {|x| ignore.include? x }
    # Add dimensionless quantities if they are in the NOT_NUMBERS list
    # This allows terms like '747'
    terms.concat quantities.select{|x| x.unit == Unit.dimensionless && NOT_NUMBERS.include?(x.value.to_i.to_s)}.map{|x| x.value.to_i.to_s}
    # All done, carry on.
    return quantities, terms
  end

end