Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = false
  config.consider_all_requests_local = false
  config.hosts = [ "www.example.org", "example.org", "localhost", "127.0.0.1" ]
end
