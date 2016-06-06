Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'food#index'
  get 'viikko/:week_no' => 'food#index', as: 'week_no'
end
