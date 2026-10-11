Rails.application.routes.draw do
  get "/up", to: "health#live"
  get "/health", to: "health#ready"
  post "/fixtures/probes", to: "probes#create"
  get "/fixtures/probes/:id", to: "probes#show"
  match "*path", to: "application#closed", via: :all
end
