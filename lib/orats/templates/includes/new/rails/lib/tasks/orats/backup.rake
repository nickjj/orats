namespace :orats do
  desc 'Create a backup of your application for a specific environment'
  task :backup do
    if File.exist?('.env') && File.file?('.env')
      require 'dotenv'
      Dotenv.load
      source_external_env = ''
    else
      source_external_env = '. /etc/default/app_name &&'
    end

    # hack'ish way to run the backup command with elevated privileges, it won't prompt for a password on the production
    # server because passwordless sudo has been enabled if you use the ansible setup provided by orats
    system 'sudo whoami'

    system "#{source_external_env} backup perform -t backup -c '#{File.join('lib', 'backup', 'config.rb')}' --log-path='#{File.join('log')}'"
  end
end