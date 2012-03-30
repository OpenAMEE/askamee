ActiveSupport::Inflector.inflections do |inflect|
  # Rails uses the old english for plural of cows, kine
  # override to stop comedy naming errors
  inflect.plural 'cow', 'cows'
  inflect.singular 'cows', 'cow'
  inflect.uncountable 'cattle'
  inflect.singular 'minibuses', 'minibus' # singular is a minibu otherwise
end
