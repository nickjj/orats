require 'securerandom'
require 'orats/commands/common'
require 'orats/commands/project/rails'

module Orats
  module Commands
    class Inventory < Common
      include Project::Rails

      def initialize(target_path = '', options = {})
        super
      end

      def init
        create_inventory

        secrets_path = "#{@target_path}/secrets"
        create_secrets secrets_path

        log_task 'Update secrets path in group_vars/all.yml'
        gsub_file "#{@target_path}/#{fix_path_for_user(Common::RELATIVE_PATHS[:inventory])}",
                  '/home/yourname/dev/testproj/secrets', File.expand_path(secrets_path)

        log_task 'Update place holder app name in group_vars/all.yml'
        gsub_file "#{@target_path}/#{fix_path_for_user(Common::RELATIVE_PATHS[:inventory])}",
                  'testproj', File.basename(@target_path)

        log_task 'Add ssh keypair'
        run "ssh-keygen -t rsa -P '' -f #{secrets_path}/id_rsa"

        log_task 'Add self signed ssl certificates'
        run create_rsa_certificate(secrets_path, 'sslkey.key', 'sslcert.crt')

        log_task 'Add monit pem file'
        run "#{create_rsa_certificate(secrets_path,
                                      'monit.pem', 'monit.pem')} && openssl gendh 512 >> #{secrets_path}/monit.pem"

        install_role_dependencies unless @options[:skip_galaxy]

        log_success
      end

      private

      def create_inventory
        log_task 'Add ansible inventory'
        run "mkdir -p #{@target_path}/inventory/group_vars"

        local_to_user Common::RELATIVE_PATHS[:hosts]
        local_to_user Common::RELATIVE_PATHS[:inventory]
      end

      def local_to_user(file)
        fixed_file = fix_path_for_user(file)

        log_task "Add #{fixed_file}"
        run "cp #{base_path}/#{file} #{@target_path}/#{fixed_file}"
      end

      def create_secrets(secrets_path)
        log_task 'Add ansible secrets'
        run "mkdir #{secrets_path}"

        save_secret_string "#{secrets_path}/postgres_password"
        save_secret_string "#{secrets_path}/redis_password"
        save_secret_string "#{secrets_path}/mail_password"
        save_secret_string "#{secrets_path}/rails_token"
        save_secret_string "#{secrets_path}/devise_token"
        save_secret_string "#{secrets_path}/devise_pepper_token"
      end

      def save_secret_string(file)
        File.open(file, 'w+') { |f| f.write(SecureRandom.hex(64)) }
      end

      def create_rsa_certificate(secrets_path, keyout, out)
        "openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -subj '/C=US/ST=Foo/L=Bar/O=Baz/CN=qux.com' -keyout #{secrets_path}/#{keyout} -out #{secrets_path}/#{out}"
      end

      def install_role_dependencies
        log_task 'Update ansible roles from the galaxy'

        galaxy_install =
            "ansible-galaxy install -r #{base_path}/#{Common::RELATIVE_PATHS[:galaxyfile]} --force"

        galaxy_out = run(galaxy_install, capture: true)

        if galaxy_out.include?('you do not have permission')
          if @options[:sudo_password].empty?
            sudo_galaxy_command = 'sudo'
          else
            sudo_galaxy_command = "echo #{@options[:sudo_password]} | sudo -S"
          end

          run("#{sudo_galaxy_command} #{galaxy_install}")
        end
      end

      def log_success
        log_status_top 'success', 'Everything has been setup successfully',
                       :cyan
        puts
        log_status_bottom 'question', 'Not sure what to do?', :yellow, true
        log_status_bottom 'answer', 'Check out the inventory/hosts file',
                          :white, true
        log_status_bottom 'answer', 'Check out the inventory/group_vars/all.yml file', :white

        log_status_bottom 'question', 'Are you new to ansible?', :yellow, true
        log_status_bottom 'answer',
                          'http://docs.ansible.com/intro_getting_started.html',
                          :white
      end

      def fix_path_for_user(file)
        file.sub('templates/includes', '')
      end
    end
  end
end