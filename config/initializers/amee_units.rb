
require 'quantify'
 
Quantify::Unit.configure do

  # this stops this string breaking AMEE
  # "40 miles in a car"
  # Will be interpreted as 40 mile-inch angstroms
  unload([:are, :inch])
  
end