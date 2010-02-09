Rails::Application.routes.draw do |map|
  resources :rails_metrics, :only => [:index, :show, :destroy]
end
