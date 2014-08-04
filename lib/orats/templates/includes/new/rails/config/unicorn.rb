# heavily inspired by gitlab:
# https://github.com/gitlabhq/gitlabhq/blob/master/config/unicorn.rb.example

worker_processes 2

if ENV['RAILS_ENV'] == 'development' || ENV['RAILS_ENV'] == 'test'
  listen '0.0.0.0:3000'
else
  listen "unix:#{ENV['RUN_STATE_PATH']}/app_name", backlog: 64
end

pid "#{ENV['RUN_STATE_PATH']}/app_name.pid"

timeout 30

stdout_path "#{ENV['LOG_PATH']}/app_name.stdout.log"
stderr_path "#{ENV['LOG_PATH']}/app_name.stderr.log"

preload_app true
GC.respond_to?(:copy_on_write_friendly=) and
  GC.copy_on_write_friendly = true

check_client_connection false

before_fork do |server, worker|
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!

  # The following is only recommended for memory/DB-constrained
  # installations. It is not needed if your system can house
  # twice as many worker_processes as you have configured.
  #
  # This allows a new master process to incrementally
  # phase out the old master process with SIGTTOU to avoid a
  # thundering herd (especially in the "preload_app false" case)
  # when doing a transparent upgrade. The last worker spawned
  # will then kill off the old master process with a SIGQUIT.
  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
end
