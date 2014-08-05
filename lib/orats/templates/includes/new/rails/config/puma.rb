environment ENV['RAILS_ENV']

threads ENV['THREADS_MIN'].to_i, ENV['THREADS_MAX'].to_i
workers ENV['WORKERS'].to_i

if ENV['RAILS_ENV'] == 'development' || ENV['RAILS_ENV'] == 'test'
  bind 'tcp://0.0.0.0:3000'
else
  bind "unix:#{ENV['RUN_STATE_PATH']}/#{ENV['SERVICE']}/#{ENV['SERVICE']}"
end

pidfile "#{ENV['RUN_STATE_PATH']}/#{ENV['SERVICE']}/#{ENV['SERVICE']}.pid"

worker_timeout 30

stdout_redirect "#{ENV['LOG_PATH']}/#{ENV['SERVICE']}/" + \
                "#{ENV['SERVICE']}.access.log",
                "#{ENV['LOG_PATH']}/#{ENV['SERVICE']}/" + \
                "#{ENV['SERVICE']}.error.log"

preload_app!

restart_command 'bundle exec puma'

on_worker_boot do
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
end
