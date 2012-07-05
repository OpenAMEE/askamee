source 'http://rubygems.org'
source 'http://amee:aeC5ahx4@gems.amee.com'

gem 'rails', '3.1.1'
gem 'quantify', :git => 'https://github.com/spatchcock/quantify.git', :branch => 'master'
gem 'amee', '~> 4.4'
gem 'amee-internal', '~> 5.0'
gem 'uuidtools'
gem 'bootstrap-sass'
gem 'fastercsv'
gem 'rails_admin', :git => 'https://github.com/sferik/rails_admin.git'
gem "airbrake"
gem 'therubyracer'

# Allow CORS requests in a browser
gem 'rack-cors', :require => 'rack/cors'


group :assets do
  gem 'sass-rails',   '~> 3.1.4'
  gem 'coffee-rails', '~> 3.1.1'
  gem 'uglifier', '>= 1.0.3'
end
gem 'jquery-rails', '>= 1.0.12'

group :development, :test do
  gem 'sqlite3'
  gem 'rspec-rails'
  gem 'pry'
  gem 'heroku'
end
group :production do
  gem 'pg'
  gem 'dalli'
end
gem "devise"
gem 'rack-google_analytics', :require => "rack/google_analytics"
