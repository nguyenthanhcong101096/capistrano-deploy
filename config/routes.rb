Rails.application.routes.draw do
  get '/' => 'pages#index', as: 'root'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
