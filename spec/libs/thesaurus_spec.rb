require 'spec_helper'
require 'thesaurus'

describe Thesaurus do

  include Thesaurus

  {

    'cow' => 'cow cattle cows',
        
  }.each_pair do |input, output|
    
    it "converts '#{input}' correctly" do
      thesaurus_expand(input).should eql output
    end
    
  end


end