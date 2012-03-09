Quantify::Unit::NonSI.configure do

  # Rename long ton
  Unit.ton_uk.configure_as_canonical do |unit|
  	unit.name = 'ton'
  end

  # Make UK gallons the default type
  Unit.gal_uk.configure_as_canonical do |unit|
  	unit.name = 'gallon'
  end

end