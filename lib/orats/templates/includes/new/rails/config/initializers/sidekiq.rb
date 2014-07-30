sidekiq_config = {
    url:       ENV['CACHE_URL'],
    namespace: "ns_app::sidekiq_#{Rails.env}"
}

Sidekiq.configure_server do |config|
  config.redis = sidekiq_config
end

Sidekiq.configure_client do |config|
  config.redis = sidekiq_config
end
