Askamee::Application.routes.draw do
  mount RailsAdmin::Engine => '/admin', :as => 'rails_admin'

  get "question/new"
  root :to => "question#new"
  match "/answer" => "question#answer"
  # AJAX route for detailed answer chunks
  match '/detail' => 'question#detailed_answer'
end
