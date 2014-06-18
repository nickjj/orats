require 'securerandom'

# =============================================================================
# template for generating an orats auth project for rails 4.1.x
# =============================================================================
# view the task list at the bottom of the file
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# private functions
# -----------------------------------------------------------------------------
def generate_token
  SecureRandom.hex(64)
end

def method_to_sentence(method)
  method.tr!('_', ' ')
  method[0] = method[0].upcase
  method
end

def log_task(message)
  puts
  say_status 'task', "#{method_to_sentence(message.to_s)}:", :yellow
  puts '-'*80, ''; sleep 0.25
end

def git_commit(message)
  git add: '-A'
  git commit: "-m '#{message}'"
end

def migrate(table_name, migration='')
  utc_now    = Time.now.getutc.strftime("%Y%m%d%H%M%S")
  class_name = table_name.to_s.classify.pluralize

  file "db/migrate/#{utc_now}_create_#{table_name}.rb", %{
class Create#{class_name} < ActiveRecord::Migration
  def change
    #{migration}
  end
end
  }
end

def copy_from_local_gem(source, dest = '')
  dest = source if dest.empty?

  base_path = "#{File.expand_path File.dirname(__FILE__)}/includes/new/rails"

  run "mkdir -p #{File.dirname(dest)}" unless Dir.exist?(File.dirname(dest))
  run "cp -f #{base_path}/#{source} #{dest}"
end

# ---

def delete_app_css
  run 'rm -f app/assets/stylesheets/application.css'
end

def update_gemfile
  log_task __method__

  inject_into_file 'Gemfile', before: "\ngem 'kaminari'" do
    <<-S

gem 'devise', '~> 3.2.4'
gem 'devise-async', '~> 0.9.0'
gem 'pundit', '~> 0.2.3'
    S
  end
  git_commit 'Add authentication related gems'
end

def update_dotenv
  log_task __method__

  inject_into_file '.env', before: "\nSMTP_ADDRESS" do
    <<-CODE
TOKEN_DEVISE_SECRET: #{generate_token}
TOKEN_DEVISE_PEPPER: #{generate_token}
    CODE
  end

  inject_into_file '.env', before: "\nDATABASE_NAME" do
    <<-CODE
ACTION_MAILER_DEVISE_DEFAULT_FROM: info@#{app_name}.com
    CODE
  end
  git_commit 'Add devise tokens and default e-mail'
end

def run_bundle_install
  log_task __method__

  run 'bundle install'
end

def add_pundit
  log_task __method__

  generate 'pundit:install'
  inject_into_file 'app/controllers/application_controller.rb', after: "::Base\n" do
    <<-S
  include Pundit

    S
  end

  inject_into_file 'app/controllers/application_controller.rb', after: ":exception\n" do
    <<-S

  rescue_from Pundit::NotAuthorizedError, with: :account_not_authorized
    S
  end

  inject_into_file 'app/controllers/application_controller.rb', after: "  #end\n" do
    <<-S

    def account_not_authorized
      redirect_to request.headers['Referer'] || root_path, flash: { error: I18n.t('authorization.error') }
    end
    S
  end
  git_commit 'Add pundit policy and controller logic'
end

def add_devise_initializers
  log_task __method__

  copy_from_local_gem 'config/initializers/devise_async.rb'
  generate 'devise:install'
  git_commit 'Add the devise and devise async initializers'
end

def update_devise_initializer
  log_task 'Update the devise initializer'

  gsub_file 'config/initializers/devise.rb',
            "'please-change-me-at-config-initializers-devise@example.com'", "ENV['ACTION_MAILER_DEVISE_DEFAULT_EMAIL']"
  gsub_file 'config/initializers/devise.rb', /(?<=key = )'\w{128}'/, "ENV['TOKEN_DEVISE_SECRET']"
  gsub_file 'config/initializers/devise.rb', /(?<=pepper = )'\w{128}'/, "ENV['TOKEN_DEVISE_PEPPER']"
  gsub_file 'config/initializers/devise.rb', '# config.timeout_in = 30.minutes',
            'config.timeout_in = 2.hours'

  gsub_file 'config/initializers/devise.rb', '# config.expire_auth_token_on_timeout = false',
            'config.expire_auth_token_on_timeout = true'
  gsub_file 'config/initializers/devise.rb', '# config.lock_strategy = :failed_attempts',
            'config.lock_strategy = :failed_attempts'
  gsub_file 'config/initializers/devise.rb', '# config.unlock_strategy = :both',
            'config.unlock_strategy = :both'
  gsub_file 'config/initializers/devise.rb', '# config.maximum_attempts = 20',
            'config.maximum_attempts = 7'
  gsub_file 'config/initializers/devise.rb', '# config.unlock_in = 1.hour',
            'config.unlock_in = 2.hours'
  gsub_file 'config/initializers/devise.rb', '# config.last_attempt_warning = false',
            'config.last_attempt_warning = true'
  git_commit 'Update the devise defaults'
end

def update_sidekiq_config
  log_task __method__

  append_file 'config/sidekiq.yml' do
    <<-S
  - mailer
    S
  end
  git_commit 'Add the devise mailer queue to sidekiq'
end

def update_routes
  log_task __method__

  gsub_file 'config/routes.rb', "mount Sidekiq::Web => '/sidekiq'\n", ''
  inject_into_file 'config/routes.rb', after: "collection\n  end\n" do
    <<-S

  # disable users from being able to register by uncommenting the lines below
  # get 'accounts/sign_up(.:format)', to: redirect('/')
  # post 'accounts(.:format)', to: redirect('/')

  # disable users from deleting their own account by uncommenting the line below
  # delete 'accounts(.:format)', to: redirect('/')

  devise_for :accounts

  authenticate :account, lambda { |account| account.is?(:admin) } do
    mount Sidekiq::Web => '/sidekiq'
  end

    S
  end
  git_commit 'Add the devise route and protect sidekiq with authentication'
end

def add_en_locale_for_authorization
  log_task __method__

  gsub_file 'config/locales/en.yml', "hello: \"Hello world\"\n", ''
  append_file 'config/locales/en.yml' do
    <<-S
authorization:
    error: 'You are not authorized to perform this action.'
    S
  end
  git_commit 'Add en locale entry for authorization errors'
end

def add_devise_migration
  log_task __method__

  migrate :accounts, %{
    create_table(:accounts) do |t|
      ## Database authenticatable
      t.string :email,              :null => false, :default => ''
      t.string :encrypted_password, :null => false, :default => ''

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, :default => 0, :null => false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Lockable
      t.integer  :failed_attempts, :default => 0, :null => false # Only if lock strategy is :failed_attempts
      t.string   :unlock_token # Only if unlock strategy is :email or :both
      t.datetime :locked_at

      ## Role
      t.string :role, default: 'guest'

      t.timestamps
    end

    add_index :accounts, :email,                :unique => true
    add_index :accounts, :reset_password_token, :unique => true
    add_index :accounts, :unlock_token,         :unique => true
  }
  git_commit 'Add devise model migration'
end

def add_account_model
  log_task __method__

  copy_from_local_gem 'app/models/account.rb'
  git_commit 'Add account model'
end

def add_seed_user
  log_task __method__

  append_file 'db/seeds.rb', "\nAccount.create({ email: \"admin@#{app_name}.com\", password: \"password\",
                                                                                 role: \"admin\" })"
  git_commit 'Add seed user'
end

def update_test_helper
  log_task __method__
  inject_into_file 'test/test_helper.rb', after: "end\n" do
    <<-S

class ActionController::TestCase
  include Devise::TestHelpers
end
    S
  end
  git_commit 'Add devise test helper'
end

def add_account_fixtures
  log_task __method__
  copy_from_local_gem 'test/fixtures/accounts.yml'
  git_commit 'Add account fixtures'
end

def add_account_unit_tests
  log_task __method__

  copy_from_local_gem 'test/models/account_test.rb'
  git_commit 'Add account unit tests'
end

def add_current_user_alias
  log_task __method__

  inject_into_file 'app/controllers/application_controller.rb', after: "::Base\n" do
    <<-S
  alias_method :current_user, :current_account

    S
  end
  git_commit 'Add current_user alias'
end

def add_devise_controller_override
  log_task __method__
  inject_into_file 'app/controllers/application_controller.rb', before: "end\n" do
    <<-S

  private

    # override devise to customize the after sign in path
    #def after_sign_in_path_for(resource)
    #  if resource.is? :admin
    #    admin_path
    #  else
    #    somewhere_path
    #  end
    #end
    S
  end
  git_commit 'Add devise after_sign_in_path_for override'
end

def add_devise_views
  log_task __method__

  copy_from_local_gem 'app/views/devise/confirmations/new.html.erb'
  copy_from_local_gem 'app/views/devise/mailer/confirmation_instructions.html.erb'
  copy_from_local_gem 'app/views/devise/mailer/confirmation_instructions.html.erb'
  copy_from_local_gem 'app/views/devise/mailer/reset_password_instructions.html.erb'
  copy_from_local_gem 'app/views/devise/mailer/unlock_instructions.html.erb'
  copy_from_local_gem 'app/views/devise/passwords/edit.html.erb'
  copy_from_local_gem 'app/views/devise/passwords/new.html.erb'
  copy_from_local_gem 'app/views/devise/registrations/edit.html.erb'
  copy_from_local_gem 'app/views/devise/registrations/new.html.erb'
  copy_from_local_gem 'app/views/devise/sessions/new.html.erb'
  copy_from_local_gem 'app/views/devise/unlocks/new.html.erb'
  copy_from_local_gem 'app/views/devise/shared/_links.html.erb'
  git_commit 'Add devise views'
end

def add_auth_links_to_the_navbar
  log_task __method__

  copy_from_local_gem 'app/views/layouts/_navigation_auth.html.erb'
  inject_into_file 'app/views/layouts/_navigation.html.erb', after: "</ul>\n" do
    <<-S
      <ul class="nav navbar-nav nav-auth">
        <%= render 'layouts/navigation_auth' %>
      </ul>
    S
  end

  append_file 'app/assets/stylesheets/application.css.scss' do
    <<-S

@media (min-width: $screen-sm) {
  .nav-auth {
    float: right;
  }
}
    S
  end
  git_commit 'Add authentication links to the layout'
end

def remove_unused_files_from_git
  log_task __method__

  git add: '-u'
  git_commit 'Remove unused files'
end

# ---

delete_app_css
update_gemfile
update_dotenv
run_bundle_install
add_pundit
add_devise_initializers
update_devise_initializer
update_sidekiq_config
update_routes
add_en_locale_for_authorization
add_devise_migration
add_account_model
add_seed_user
update_test_helper
add_account_fixtures
add_account_unit_tests
add_current_user_alias
add_devise_controller_override
add_devise_views
add_auth_links_to_the_navbar
remove_unused_files_from_git