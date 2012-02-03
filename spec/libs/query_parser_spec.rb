require 'spec_helper'
require 'query_parser'

describe QueryParser do

  include QueryParser

  {

    '10kg of beef' => {
      :inputs => ['10.0 kg'],
      :terms => ['beef']
    },
    '10 kg beef' => {
      :inputs => ['10.0 kg'],
      :terms => ['beef']
    },
    '100km in a car' => {
      :inputs => ['100.0 km'],
      :terms => ['car']
    },
    '42kWh of electricity in the UK' => {
      :inputs => ['42.0 kWh'],
      :terms => ['electricity', 'UK']
    },
    '10 cows' => {
      :inputs => ['10.0 '],
      :terms => ['cows']
    },
    '1 long haul flight' => {
      :inputs => ['1.0 '],
      :terms => ['long', 'haul', 'flight']
    },
    'fly from LAX to LHR in a 747' => {
      :inputs => ['from:LAX', 'to:LHR'],
      :terms => ['fly', '747']
    },
    # Pending implementation of non-IATA routing
    # 'fly from london to new york' => {
    #   :inputs => ['from:london', 'to:new york'],
    #   :terms => ['fly']
    # },
    # 'fly from new york to london' => {
    #   :inputs => ['from:new york', 'to:london'],
    #   :terms => ['fly']
    # },
        
  }.each_pair do |query, results|
    
    it "should parse '#{query}' correctly" do
      # Parse string
      inputs, terms = parse_query(query)
      # Check inputs are parsed correctly
      inputs.map{|x| x.to_s}.sort.should eql results[:inputs].sort
      # Check remaining terms are correct
      terms.sort.should eql results[:terms].sort
    end
    
  end


end