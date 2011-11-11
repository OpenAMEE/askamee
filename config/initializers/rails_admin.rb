# RailsAdmin config file. Generated on November 11, 2011 14:30
# See github.com/sferik/rails_admin for more informations

RailsAdmin.config do |config|
  
  # Set the admin name here (optional second array element will appear in a beautiful RailsAdmin red ©)
  config.main_app_name = ['Ask AMEE', 'Admin']

  #  ==> Authentication (before_filter)
  config.authenticate_with do
    user = Rails.env.production? ? ENV['ADMIN_USER'] : 'admin'
    pass = Rails.env.production? ? ENV['ADMIN_PASSWORD'] : 'password'
    authenticate_or_request_with_http_basic('AskAMEE Admin') do |username, password|
      username == user  && password == pass
    end
  end

end
