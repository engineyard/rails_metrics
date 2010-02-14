Rails::Application.routes.draw do |map|
  resources :rails_metrics, :only => [:index, :show, :destroy] do
    get :all, :on => :collection
    get :chart, :on => :member
    delete :destroy_all, :on => :collection
  end
end
