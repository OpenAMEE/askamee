Askamee::Application.routes.draw do
  get "question/new"
  root :to => "question#new"
  match "/answer" => "question#answer"
  # AJAX route for detailed answer chunks
  match '/detail' => 'question#detailed_answer'
end
