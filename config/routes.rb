Rails.application.routes.draw do
  resources :rails_metrics, :only => [:index, :show, :destroy] do
    collection do
      get :all
      delete :destroy_all
    end

    get :chart, :on => :member
  end
end
