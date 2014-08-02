environment ENV['RAILS_ENV']

threads ENV['PUMA_THREADS_MIN'].to_i, ENV['PUMA_THREADS_MAX'].to_i
workers ENV['PUMA_WORKERS'].to_i

if ENV['RAILS_ENV'] == 'development' || ENV['RAILS_ENV'] == 'test'
  bind 'tcp://0.0.0.0:3000'
else
  # You should write out your sockets and pids to /var/run/app_name if you are
  # deploying to a debian based system. If you are using ginas to provision
  # your servers this is where it will look by default.
  run_path = '/var/run/app_name'
  bind "unix:#{run_path}/app_name"
  pidfile "#{run_path}/app_name.pid"
end

# https://github.com/puma/puma/blob/master/examples/config.rb#L125
prune_bundler

restart_command 'bundle exec bin/puma'

on_worker_boot do
  require 'active_record'

  config_path = File.expand_path('../database.yml', __FILE__)
  ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished
  ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'] || YAML.load_file(config_path)[ENV['RAILS_ENV']])
end
