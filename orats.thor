module Orats
  class Rails < Thor
    include Thor::Actions

    desc 'base APP_NAME', 'Create a new rails app using the base template.'
    def base(app_name)
      run "rails new #{app_name} --skip-bundle --template https://raw.github.com/nickjj/orats/master/templates/base.rb"
    end

    desc 'auth APP_NAME', 'Add authentication/authorization to a base template.'
    def auth(app_name)
      run "rails new #{app_name} --skip --skip-bundle --template https://raw.github.com/nickjj/orats/master/templates/authentication-and-authorization.rb"
    end

    desc 'all APP_NAME', 'Create a new rails app using every app template.'
    def all(app_name)
      base(app_name)
      auth(app_name)
      puts
      puts
      puts  '', '!'*80
      say_status  'warning', "\e[1mYou ran a composed template, you must follow these steps INSTEAD:\e[0m", :yellow
      puts
      say_status  'action', "\e[1mEdit the .env file located in the rails root directory
                with your details and then run:\e[0m", :cyan
      say_status  'command', "cd #{app_name} && bundle exec rake db:create:all db:migrate db:test:prepare db:seed", :magenta
      puts  '!'*80, ''

      puts  '', '='*80
      say_status  'action', "\e[1mStart the server by running the command below:\e[0m", :cyan
      say_status  'command', 'bundle exec foreman start', :magenta
      puts  '='*80, ''
    end
  end
end