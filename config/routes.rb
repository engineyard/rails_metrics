Rails::Application.routes.draw do |map|
  resources :rails_metrics, :only => [:index, :show, :destroy] do
    delete :destroy_all, :on => :collection
  end
end
