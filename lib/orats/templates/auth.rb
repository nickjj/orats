# =====================================================================================================
# Template for generating an orats auth project for Rails 4.1.x
# =====================================================================================================

require 'securerandom'

def generate_token
  SecureRandom.hex(64)
end

def log_task(message)
  puts
  say_status  'task', "#{message}...", :yellow
  puts        '-'*80, ''; sleep 0.25
end

def git_commit(message)
  git add: '-A'
  git commit: "-m '#{message}'"
end

def migrate(table_name, migration='')
  utc_now = Time.now.getutc.strftime("%Y%m%d%H%M%S")
  class_name = table_name.to_s.classify.pluralize

  file "db/migrate/#{utc_now}_create_#{table_name}.rb", %{
class Create#{class_name} < ActiveRecord::Migration
  def change
    #{migration}
  end
end
  }
end

# ----- Delete application.css ------------------------------------------------------------------------

# This gets created by rails automatically when you make a new project
run 'rm -f app/assets/stylesheets/application.css'

# ----- Modify Gemfile --------------------------------------------------------------------------------

log_task 'Update Gemfile'
inject_into_file 'Gemfile', before: "\ngem 'kaminari'" do <<-S

gem 'devise', '~> 3.2.4'
gem 'devise-async', '~> 0.9.0'
gem 'pundit', '~> 0.2.3'
S
end
git_commit 'Add authentication related gems'

log_task 'Run bundle install, it should not take too long'
run 'bundle install'

log_task 'Update the sidekiq config'
append_file 'config/sidekiq.yml' do <<-S
  - mailer
S
end
git_commit 'Add the devise mailer queue to sidekiq'

log_task 'Update the test helper'
inject_into_file 'test/test_helper.rb', after: "end\n" do <<-S

class ActionController::TestCase
  include Devise::TestHelpers
end
S
end
git_commit 'Add devise test helper'

log_task 'Add account fixtures'
file 'test/fixtures/accounts.yml' do <<-S
foo:
  id: 1
  email: foo@bar.com
  encrypted_password: passwordisnotreallyencrypted
  role: admin
  created_at: 2012-01-01 01:45:17
  current_sign_in_at: 2013-03-15 11:22:33

no_role:
  id: 2
  email: joey@almostcool.com
  encrypted_password: hackthegibson
  created_at: 1995-09-15 08:10:12

bad_role:
  id: 3
  email: hello@world.com
  encrypted_password: reallysecure
  role: ahhhh
  created_at: 2011-09-20 10:10:10

beep:
  id: 4
  email: beep@beep.com
  encrypted_password: beepbeepbeep
  created_at: 2010-03-6 05:15:45
S
end
git_commit 'Add account fixtures'

log_task 'Add account unit test'
file 'test/models/account_test.rb' do <<-S
require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  def setup
    @account = accounts(:foo)
  end

  def teardown
    @account = nil
  end

  test 'expect new account' do
    assert @account.valid?
    assert_not_nil @account.email
    assert_not_nil @account.encrypted_password
  end

  test 'expect guest to be default role' do
    no_role = accounts(:no_role)
    assert_equal 'guest', no_role.role
  end

  test 'expect invalid role to not save' do
    bad_role = accounts(:bad_role)
    assert_not bad_role.valid?
  end

  test 'expect e-mail to be unique' do
    duplicate = Account.create(email: 'foo@bar.com')

    assert_not duplicate.valid?
  end

  test 'expect random password if password is empty' do
    @account.password = ''
    @account.encrypted_password = ''
    @account.save

    random_password = Account.generate_password
    assert_equal 10, random_password.length
  end

  test 'expect random password of 20 characters' do
    assert_equal 20, Account.generate_password(20).length
  end
end
S
end
git_commit 'Add account unit tests'

git add: '-A'
git commit: "-m 'Add the account unit tests'"

log_task 'Add account model'
file 'app/models/account.rb' do <<-'S'
class Account < ActiveRecord::Base
  ROLES = %w[admin guest]

  devise :database_authenticatable, :registerable, :recoverable, :rememberable,
         :trackable, :timeoutable, :lockable, :validatable, :async

  before_validation :ensure_password, on: :create

  after_save :invalidate_cache

  validates :role, inclusion: { in: ROLES }

  def self.serialize_from_session(key, salt)
    # store the current_account in the cache so we do not perform a db lookup on each authenticated page
    single_key = key.is_a?(Array) ? key.first : key

    Rails.cache.fetch("account:#{single_key}") do
      Account.where(id: single_key).entries.first
    end
  end

  def self.generate_password(length = 10)
    Devise.friendly_token.first(length)
  end

  def is?(role_check)
    role.to_sym == role_check
  end

  private

    def ensure_password
      # only generate a password if it does not exist
      self.password ||= Account.generate_password
    end

    def invalidate_cache
      Rails.cache.delete("account:#{id}")
    end
end
S
end
git_commit 'Add account model'

log_task 'Add devise model migration'
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

log_task 'Add seed user'
append_file 'db/seeds.rb', "\nAccount.create({ email: \"admin@#{app_name}.com\", password: \"password\", role: \"admin\" })"
git_commit 'Add seed user'

log_task 'Add en locale for authorization errors'
gsub_file 'config/locales/en.yml', "hello: \"Hello world\"\n", ''
append_file 'config/locales/en.yml' do <<-S
authorization:
    error: 'You are not authorized to perform this action.'
S
end
git_commit 'Add en locale entry for authorization errors'

log_task 'Add current_user alias'
inject_into_file 'app/controllers/application_controller.rb', after: "::Base\n" do <<-S
  alias_method :current_user, :current_account

S
end
git_commit 'Add current_user alias'

log_task 'Add devise after_sign_in_path_for override'
inject_into_file 'app/controllers/application_controller.rb', before: "end\n" do <<-S

  private

    # Override devise to customize the after sign in path.
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

log_task 'Add devise views'
file 'app/views/devise/confirmations/new.html.erb' do <<-S
<%
  title 'Confirm'
  meta_description '...'
  heading 'Confirm'
%>

<div class="row">
  <div class="col-sm-4">
    <%= form_for(resource, as: resource_name, url: confirmation_path(resource_name), html: { method: :post }) do |f| %>
      <div class="form-group">
        <%= f.label :email %>
        <%= f.email_field :email, class: 'form-control', maxlength: 254, autofocus: true,
        data: {
          'rule-required' => 'true',
          'rule-maxlength' => '254'
        } %>
      </div>
      <%= button_tag type: 'submit', class: 'btn btn-primary' do %>
        Send
      <% end %>
    <% end %>
  </div>
  <div class="col-sm-6 col-sm-offset-2">
    <%= render 'devise/shared/links' %>
  </div>
</div>
S
end
file 'app/views/devise/mailer/confirmation_instructions.html.erb' do <<-S
<p>Welcome <%= @email %>!</p>

<p>You can confirm your account email through the link below:</p>

<p><%= link_to 'Confirm my account', confirmation_url(@resource, confirmation_token: @token) %></p>
S
end
file 'app/views/devise/mailer/reset_password_instructions.html.erb' do <<-S
<p>Hello <%= @resource.email %>!</p>

<p>Someone has requested a link to change your password. You can do this through the link below.</p>

<p><%= link_to 'Change my password', edit_password_url(@resource, reset_password_token: @token) %></p>

<p>If you didn't request this, please ignore this email.</p>
<p>Your password won't change until you access the link above and create a new one.</p>
S
end
file 'app/views/devise/mailer/unlock_instructions.html.erb' do <<-S
<p>Hello <%= @resource.email %>!</p>

<p>Your account has been locked due to an excessive number of unsuccessful sign in attempts.</p>

<p>Click the link below to unlock your account:</p>

<p><%= link_to 'Unlock my account', unlock_url(@resource, unlock_token: @token) %></p>
S
end
file 'app/views/devise/passwords/edit.html.erb' do <<-S
<%
  title 'Change your password'
  meta_description '...'
  heading 'Change your password'
%>

<div class="row">
  <div class="col-sm-4">
    <%= form_for resource, as: resource_name, url: password_path(resource_name), html: { method: :put } do |f| %>
      <%= f.hidden_field :reset_password_token %>
      <div class="form-group">
        <%= f.label :password, 'New password' %>
        <%= f.password_field :password, maxlength: 128, class: 'form-control', autofocus: true,
        data: {
          'rule-required' => 'true',
          'rule-minlength' => '8',
          'rule-maxlength' => '128'
        } %>
      </div>
      <%= button_tag type: 'submit', class: 'btn btn-primary' do %>
        Send
      <% end %>
    <% end %>
  </div>
  <div class="col-sm-6 col-sm-offset-2">
    <%= render 'devise/shared/links' %>
  </div>
</div>
S
end
file 'app/views/devise/passwords/new.html.erb' do <<-S
<%
  title 'Forgot your password?'
  meta_description '...'
  heading 'Forgot your password?'
%>

<div class="row">
  <div class="col-sm-4">
    <%= form_for resource, as: resource_name, url: password_path(resource_name), html: { method: :post } do |f| %>
      <div class="form-group">
        <%= f.label :email %>
        <%= f.email_field :email, class: 'form-control', autofocus: true, maxlength: 254,
        data: {
          'rule-required' => 'true',
          'rule-maxlength' => '254'
        } %>
      </div>
      <%= button_tag type: 'submit', class: 'btn btn-primary' do %>
        Send
      <% end %>
    <% end %>
  </div>
  <div class="col-sm-6 col-sm-offset-2">
    <%= render 'devise/shared/links' %>
  </div>
</div>
S
end
file 'app/views/devise/registrations/edit.html.erb' do <<-S
<%
  title 'Edit your account'
  meta_description '...'
  heading 'Edit your account'
%>

<div class="row">
  <div class="col-sm-6">
    <%= form_for resource, as: resource_name, url: registration_path(resource_name), html: { method: :patch } do |f| %>
      <div class="form-group">
        <%= f.label :current_password %>
        <span class="help-block form-help-adjust-margin">
          <small>
            Supply your current password to make any changes
          </small>
        </span>
        <%= f.password_field :current_password, maxlength: 128, class: 'form-control',
        data: {
          'rule-required' => 'true',
          'rule-minlength' => '8',
          'rule-maxlength' => '128'
        } %>
      </div>
      <div class="form-group">
        <%= f.label :email %>
        <%= f.email_field :email, class: 'form-control', maxlength: 254, autofocus: true %>
      </div>
      <% if devise_mapping.confirmable? && resource.pending_reconfirmation? %>
        <h3>Currently waiting confirmation for: <%= resource.unconfirmed_email %></h3>
      <% end %>
      <div class="form-group">
        <%= f.label :password %>
        <span class="help-block form-help-adjust-margin">
          <small>
            Leave this blank if you do not want to change it
          </small>
        </span>
        <%= f.password_field :password, class: 'form-control' %>
      </div>
      <%= button_tag type: 'submit', class: 'btn btn-primary' do %>
        Save
      <% end %>
    <% end %>
  </div>
  <div class="col-sm-6">
    <p>
      Unhappy? <%= button_to 'Cancel my account', registration_path(resource_name), method: :delete %>
    </p>
  </div>
</div>
S
end
file 'app/views/devise/registrations/new.html.erb' do <<-S
<%
  title 'Register a new account'
  meta_description '...'
  heading 'Register a new account'
%>

<div class="row">
  <div class="col-sm-4">
    <%= form_for resource, as: resource_name, url: registration_path(resource_name) do |f| %>
      <div class="form-group">
        <%= f.label :email %>
        <%= f.email_field :email, class: 'form-control', maxlength: 254, autofocus: true %>
      </div>
      <div class="form-group">
        <%= f.label :password %>
        <%= f.password_field :password, maxlength: 128, class: 'form-control',
        data: {
          'rule-required' => 'true',
          'rule-minlength' => '8',
          'rule-maxlength' => '128'
        } %>
      </div>
      <%= button_tag type: 'submit', class: 'btn btn-primary' do %>
        Register
      <% end %>
    <% end %>
  </div>
  <div class="col-sm-6 col-sm-offset-2">
    <%= render 'devise/shared/links' %>
  </div>
</div>
S
end
file 'app/views/devise/sessions/new.html.erb' do <<-S
<%
  title 'Sign in'
  meta_description '...'
  heading 'Sign in'
%>

<div class="row">
  <div class="col-sm-4">
    <%= form_for resource, as: resource_name, url: session_path(resource_name) do |f| %>
      <div class="form-group">
        <%= f.label :email %>
        <%= f.email_field :email, maxlength: 254, class: 'form-control', autofocus: true %>
      </div>
      <div class="form-group">
        <%= f.label :password %>
        <%= f.password_field :password, maxlength: 128, class: 'form-control',
        data: {
          'rule-required' => 'true',
          'rule-minlength' => '8',
          'rule-maxlength' => '128'
        } %>
      </div>
      <% if devise_mapping.rememberable? -%>
        <div class="checkbox">
          <%= f.label :remember_me do %>
            <%= f.check_box :remember_me %> Stay signed in
          <% end %>
        </div>
      <% end -%>
      <%= button_tag type: 'submit', class: 'btn btn-primary' do %>
        Sign in
      <% end %>
    <% end %>
  </div>
  <div class="col-sm-6 col-sm-offset-2">
    <h4 class="success-color">Having trouble accessing your account?</h4>
    <%= render 'devise/shared/links' %>
  </div>
</div>
S
end
file 'app/views/devise/unlocks/new.html.erb' do <<-S
<%
  title 'Re-send unlock instructions'
  meta_description '...'
  heading 'Re-send unlock instructions'
%>

<div class="row">
  <div class="col-sm-4">
    <%= form_for(resource, as: resource_name, url: unlock_path(resource_name), html: { method: :post }) do |f| %>
      <div class="form-group">
        <%= f.label :email %>
        <%= f.email_field :email, class: 'form-control', maxlength: 254, autofocus: true,
        data: {
          'rule-required' => 'true',
          'rule-maxlength' => '254'
        } %>
      </div>
      <%= button_tag type: 'submit', class: 'btn btn-primary' do %>
        Send
      <% end %>
    <% end %>
  </div>
  <div class="col-sm-6 col-sm-offset-2">
    <%= render 'devise/shared/links' %>
  </div>
</div>
S
end
file 'app/views/devise/shared/_links.html.erb' do <<-'S'
<%= content_tag(:h4, 'Or do something else') if controller_name != 'sessions' %>
<ul>
  <%- if controller_name != 'sessions' %>
    <li>
      <%= link_to 'Sign in', new_session_path(resource_name) %>
    </li>
  <% end -%>

  <%- if devise_mapping.registerable? && controller_name != 'registrations' %>
    <li>
      <%= link_to 'Sign up', new_registration_path(resource_name) %>
    </li>
  <% end -%>

  <%- if devise_mapping.recoverable? && controller_name != 'passwords' && controller_name != 'registrations' %>
    <li>
      <%= link_to 'Forgot your password?', new_password_path(resource_name) %>
    </li>
  <% end -%>

  <%- if devise_mapping.confirmable? && controller_name != 'confirmations' %>
    <li>
      <%= link_to 'Re-send confirmation instructions?', new_confirmation_path(resource_name) %>
    </li>
  <% end -%>

  <%- if devise_mapping.lockable? && resource_class.unlock_strategy_enabled?(:email) && controller_name != 'unlocks' %>
    <li>
      <%= link_to 'Are you locked out of your account?', new_unlock_path(resource_name) %>
    </li>
  <% end -%>

  <%- if devise_mapping.omniauthable? %>
    <%- resource_class.omniauth_providers.each do |provider| %>
      <li><%= link_to "Sign in with #{provider.to_s.titleize}", omniauth_authorize_path(resource_name, provider) %></li>
    <% end -%>
  <% end -%>
</ul>
S
end
git_commit 'Add devise views'

log_task 'Add authentication links to the navigation'
file 'app/views/layouts/_navigation_auth.html.erb', <<-S
<% if current_account %>
  <li>
    <%= link_to 'Settings', edit_account_registration_path %>
  </li>
  <li>
    <%= link_to 'Sign out', destroy_account_session_path, method: :delete %>
  </li>
<% else %>
  <li>
    <%= link_to 'Sign in', new_account_session_path %>
  </li>
  <li>
    <%= link_to 'Register', new_account_registration_path %>
  </li>
<% end %>
S
inject_into_file 'app/views/layouts/_navigation.html.erb', after: "</ul>\n" do <<-S
      <ul class="nav navbar-nav nav-auth">
        <%= render 'layouts/navigation_auth' %>
      </ul>
S
end
append_file 'app/assets/stylesheets/application.css.scss' do <<-S

@media (min-width: $screen-sm) {
  .nav-auth {
    float: right;
  }
}
S
end
git_commit 'Add authentication links to the layout'

log_task 'Add devise environment variables'
inject_into_file '.env', before: "\nSMTP_ADDRESS" do <<-CODE
TOKEN_DEVISE_SECRET: #{generate_token}
TOKEN_DEVISE_PEPPER: #{generate_token}
CODE
end
inject_into_file '.env', before: "\nDATABASE_NAME" do <<-CODE
ACTION_MAILER_DEVISE_DEFAULT_FROM: info@#{app_name}.com
CODE
end
git_commit 'Add devise tokens and default e-mail'

log_task 'Add the devise/devise-async initializers'
file 'config/initializers/devise_async.rb', 'Devise::Async.backend = :sidekiq'
generate 'devise:install'
git_commit 'Add the devise and devise async initializers'

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

log_task 'Update the routes file'
inject_into_file 'config/routes.rb', after: "collection\n  end\n" do <<-S

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
git_commit 'Add devise to the routes file'

log_task 'Add pundit'
generate 'pundit:install'
inject_into_file 'app/controllers/application_controller.rb', after: "::Base\n" do <<-S
  include Pundit

S
end
inject_into_file 'app/controllers/application_controller.rb', after: ":exception\n" do <<-S

  rescue_from Pundit::NotAuthorizedError, with: :account_not_authorized
S
end
inject_into_file 'app/controllers/application_controller.rb', after: "  #end\n" do <<-S

    def account_not_authorized
      redirect_to request.headers['Referer'] || root_path, flash: { error: I18n.t('authorization.error') }
    end
S
end
git_commit 'Add pundit policy and controller logic'

log_task 'Remove unused files from git'
git add: '-u'
git_commit 'Remove unused files'