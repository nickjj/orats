ENV['CACHE_PASSWORD'].present? ? pass_string = ":#{ENV['CACHE_PASSWORD']}@" : pass_string = ''

redis_host = "#{pass_string}#{ENV['CACHE_HOST']}"

sidekiq_config = {
    url:       "redis://#{redis_host}:#{ENV['CACHE_PORT']}/#{ENV['CACHE_DATABASE']}",
    namespace: "ns_app::sidekiq_#{Rails.env}"
}

Sidekiq.configure_server do |config|
  config.redis = sidekiq_config
end

Sidekiq.configure_client do |config|
  config.redis = sidekiq_config
end