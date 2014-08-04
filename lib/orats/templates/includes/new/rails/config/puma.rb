environment ENV['RAILS_ENV']

threads ENV['BACKEND_THREADS_MIN'].to_i, ENV['BACKEND_THREADS_MAX'].to_i
workers ENV['BACKEND_WORKERS'].to_i

if ENV['RAILS_ENV'] == 'development' || ENV['RAILS_ENV'] == 'test'
  bind 'tcp://0.0.0.0:3000'
else
  bind "unix:#{ENV['RUN_STATE_PATH']}/app_name"
end

pidfile "#{ENV['RUN_STATE_PATH']}/app_name.pid"

# https://github.com/puma/puma/blob/master/examples/config.rb#L125
prune_bundler

restart_command 'bundle exec bin/puma'

on_worker_boot do
  require 'active_record'

  ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished
  ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
end
