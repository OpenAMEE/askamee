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
    # Extract journey info
    journeys, terms = extract_journey(terms)
    quantities.concat journeys
    # Ignore common words
    ignore = [
      "emissions",
      "impact",
      "and",
      "of",
      "the",
      "a",
      "in",
      "for",
      "on",
      "an"
    ]
    terms.delete_if {|x| ignore.include? x }
    # Move dimensionless quantities from quantities to terms if they are in the NOT_NUMBERS list
    # This allows terms like '747'. Unfortunately it means you can't calculate '747 cows'.
    quantities.select{|x| x.is_a?(Quantity) && x.unit == Unit.dimensionless && NOT_NUMBERS.include?(x.value.to_i.to_s)}.each do |quantity|
      terms << quantity.value.to_i.to_s
      quantities.delete quantity
    end
    # All done, carry on.
    return quantities, terms
  end

  def extract_journey(terms)
    match = terms.join(' ').match(/^(.*) from ([A-Z]{3}) to ([A-Z]{3})/i)
    if match
      journeys = ["from:#{match[2]}", "to:#{match[3]}"]
      terms = match[1].split(' ')
      return journeys, terms
    else
      return [], terms
    end
  end

end