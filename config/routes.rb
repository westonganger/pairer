Pairer::Engine.routes.draw do
  get :sign_in, to: "main#sign_in"
  post :sign_in, to: "main#sign_in"
  get :sign_out, to: "main#sign_out"

  resources :boards, controller: :main, except: [:new, :edit] do
    member do
      post :shuffle
      post :create_person
      post :lock_person
      delete :delete_person
      post :create_group
      post :lock_group
      delete :delete_group
      post :update_group
    end
  end

  get '/robots', to: 'application#robots', constraints: ->(req){ req.format == :text }

  match '*a', to: 'application#render_404', via: :get

  get "/", to: "main#index"

  root "main#index"
end
