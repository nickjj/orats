# =====================================================================================================
# Template for generating an opinionated base Rails 4.1.0 project using Ruby 2.1.0
# =====================================================================================================

# ----- Helper functions and variables ----------------------------------------------------------------

require 'securerandom'

def generate_token
  SecureRandom.hex(64)
end

def from_gem(source, destination = nil)
  base_path = "#{File.expand_path File.dirname(__FILE__)}/includes"
  file_name = source.split('/').last

  if destination.present? && file_name != destination
    if destination.include? '/'
      run "mkdir -p #{destination}"
    end
  end

  run "cp #{base_path}/#{file_name} #{destination}"
end

app_name_class = app_name.humanize

# ----- Create the git repo ----------------------------------------------------------------------------

puts
say_status  'git', 'Creating a new local git repo...', :yellow
puts        '-'*80, ''; sleep 0.25

git :init
git add: '-A'
git commit: "-m 'Initial commit'"

# ----- Modify the .gitignore file --------------------------------------------------------------------

puts
say_status  'root', 'Modifying the .gitignore file...', :yellow
puts        '-'*80, ''; sleep 0.25

append_to_file '.gitignore' do <<-TEXT

# Ignore OS and editor files.
.DS_Store
*/**.DS_Store
._*
.*.sw*
*~
.idea/

# Ignore the main environment file.
.env

# Ignore app specific folders.
/vendor/bundle
/public/assets/*

# Ignore backup paths.
/lib/backup/log/*
/lib/backup/tmp/*
TEXT
end

git add: '-A'
git commit: "-m 'Add common OS and editor files to the .gitignore file'"

# ----- Add a bundler config --------------------------------------------------------------------

# puts
# say_status  'bundle', 'Creating bundle config...', :yellow
# puts        '-'*80, ''; sleep 0.25
#
# file '.bundle/config' do <<-CODE
# ---
# BUNDLE_WITHOUT: production:staging
# CODE
# end
#
# git add: '-A'
# git commit: "-m 'Add .bundle/config to ignore production:staging in development mode'"

# ----- Create a few root files -----------------------------------------------------------------------

puts
say_status  'root', 'Creating root files...', :yellow
puts        '-'*80, ''; sleep 0.25

file '.ruby-version', '2.1.2'

git add:    '-A'
git commit: "-m 'Add .ruby-version file for common ruby version managers'"

file 'Procfile' do <<-CODE
web: puma -C config/puma.rb
worker: sidekiq -C config/sidekiq.yml
CODE
end

git add:    '-A'
git commit: "-m 'Add a basic Procfile to start the puma and sidekiq processes'"

# ----- Create an .env file ---------------------------------------------------------------------------

puts
say_status  'root', 'Creating .env file...', :yellow
puts        '-'*80, ''; sleep 0.25

file '.env' do <<-CODE
RAILS_ENV: development

PROJECT_PATH: /full/path/to/your/project
SOURCE_ENV_PATH: .env

GOOGLE_ANALYTICS_UA: ""
DISQUS_SHORT_NAME: ""
S3_ACCESS_KEY_ID: ""
S3_SECRET_ACCESS_KEY: ""
S3_REGION: ""

TOKEN_RAILS_SECRET: #{generate_token}

SMTP_ADDRESS: smtp.gmail.com
SMTP_PORT: 587 # 465 if you use ssl
SMTP_DOMAIN: gmail.com
SMTP_USERNAME: #{app_name}@gmail.com
SMTP_PASSWORD: thebestpassword
SMTP_AUTH: plain
SMTP_ENCRYPTION: starttls

ACTION_MAILER_HOST: localhost:3000
ACTION_MAILER_DEFAULT_FROM: info@#{app_name}.com
ACTION_MAILER_DEFAULT_TO: me@#{app_name}.com

DATABASE_NAME: #{app_name}
DATABASE_HOST: localhost
DATABASE_POOL: 25
DATABASE_TIMEOUT: 5000
DATABASE_USERNAME: postgres
DATABASE_PASSWORD: supersecrets

CACHE_HOST: localhost
CACHE_PORT: 6379
CACHE_DATABASE: 0
CACHE_PASSWORD: ""

PUMA_THREADS_MIN: 0
PUMA_THREADS_MAX: 1
PUMA_WORKERS: 0

SIDEKIQ_CONCURRENCY: 25
CODE
end

# ----- Modify the secrets yaml file -----------------------------------------------------------------------

gsub_file 'config/secrets.yml', /.*\n/, ''
append_file 'config/secrets.yml' do <<-FILE
# Be sure to restart your server when you modify this file.

# Your secret key is used for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!

# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
# You can use `rake secret` to generate a secure secret key.

# Make sure the secrets in this file are kept private
# if you're sharing your code publicly.

development: &default
  secret_key_base: <%= ENV['TOKEN_RAILS_SECRET'] %>

test:
  <<: *default

staging:
  <<: *default

production:
  <<: *default
FILE
end

git add:    '-A'
git commit: "-m 'Dry up the secrets settings'"

# ----- Modify the application file -------------------------------------------------------------------

puts
say_status  'config', 'Modifying the application file...', :yellow
puts        '-'*80, ''; sleep 0.25

inject_into_file 'config/application.rb', after: "automatically loaded.\n" do <<-CODE
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      :address              => ENV['SMTP_ADDRESS'],
      :port                 => ENV['SMTP_PORT'].to_i,
      :domain               => ENV['SMTP_DOMAIN'],
      :user_name            => ENV['SMTP_USERNAME'],
      :password             => ENV['SMTP_PASSWORD'],
      :authentication       => ENV['SMTP_AUTH']
    }
    config.action_mailer.smtp_settings[:enable_starttls_auto] = true if ENV['SMTP_ENCRYPTION'] == 'starttls'
    config.action_mailer.smtp_settings[:ssl] = true if ENV['SMTP_ENCRYPTION'] == 'ssl'

    config.action_mailer.default_options = { from: ENV['ACTION_MAILER_DEFAULT_FROM'] }
    config.action_mailer.default_url_options = { host: ENV['ACTION_MAILER_HOST'] }

    redis_store_options = { host: ENV['CACHE_HOST'],
                            port: ENV['CACHE_PORT'].to_i,
                            db: ENV['CACHE_DATABASE'].to_i,
                            namespace: '#{app_name}::cache'
                          }
    redis_store_options[:password] = ENV['CACHE_PASSWORD'] if ENV['CACHE_PASSWORD'].present?

    config.cache_store = :redis_store, redis_store_options
CODE
end

gsub_file 'config/application.rb', "# config.time_zone = 'Central Time (US & Canada)'", "config.time_zone = 'Eastern Time (US & Canada)'"

append_file 'config/application.rb' do <<-'FILE'

ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  if html_tag =~ /\<label/
    html_tag
  else
    errors = Array(instance.error_message).join(',')
    %(#{html_tag}<p class="validation-error"> #{errors}</p>).html_safe
  end
end
FILE
end

git add:    '-A'
git commit: "-m 'Add tweakable settings, update the timezone and change the way validation errors are shown'"

# ----- Modify the config files -----------------------------------------------------------------------

puts
say_status  'config', 'Modifying the config files...', :yellow
puts        '-'*80, ''; sleep 0.25

gsub_file 'config/database.yml', /.*\n/, ''
append_file 'config/database.yml' do <<-FILE
development: &default
  adapter: postgresql
  database: <%= ENV['DATABASE_NAME'] %>
  host: <%= ENV['DATABASE_HOST'] %>
  pool: <%= ENV['DATABASE_POOL'] %>
  timeout: <%= ENV['DATABASE_TIMEOUT'] %>
  username: <%= ENV['DATABASE_USERNAME'] %>
  password: <%= ENV['DATABASE_PASSWORD'] %>

test:
  <<: *default
  database: <%= ENV['DATABASE_NAME'] %>_test

staging:
  <<: *default

production:
  <<: *default
FILE
end

git add:    '-A'
git commit: "-m 'Dry up the database settings'"

file 'config/puma.rb', <<-'CODE'
environment ENV['RAILS_ENV']

threads ENV['PUMA_THREADS_MIN'].to_i,ENV['PUMA_THREADS_MAX'].to_i
workers ENV['PUMA_WORKERS'].to_i

pidfile "#{ENV['PROJECT_PATH']}/tmp/puma.pid"

if ENV['RAILS_ENV'] == 'production'
  bind "unix://#{ENV['PROJECT_PATH']}/tmp/puma.sock"
else
  port '3000'
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
CODE

git add:    '-A'
git commit: "-m 'Add the puma config'"

file 'config/sidekiq.yml', <<-CODE
---
:pidfile: <%= ENV['PROJECT_PATH'] %>/tmp/sidekiq.pid
:concurrency: <%= ENV['SIDEKIQ_CONCURRENCY'].to_i %>
:queues:
  - default
CODE

git add:    '-A'
git commit: "-m 'Add the sidekiq config'"

file 'config/sitemap.rb', <<-'CODE'
# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "http://www.app_name.com"

SitemapGenerator::Sitemap.create do
  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Examples:
  #
  # add root_path
  # add foobar_path, priority: 0.7, changefreq: 'daily'
  #
  # Iteration example:
  #
  # Article.published.find_each do |article|
  #   add article_path("#{article.id}-#{article.permalink}"), priority: 0.9, lastmod: article.updated_at
  # end
end
CODE

gsub_file 'config/sitemap.rb', 'app_name', app_name

git add:    '-A'
git commit: "-m 'Add the sitemap config'"

file 'config/schedule.rb', <<-CODE
every 1.day, at: '3:00 am' do
  rake 'orats:backup'
end

every 1.day, at: '4:00 am' do
  rake 'sitemap:refresh'
end
CODE

git add:    '-A'
git commit: "-m 'Add a sitemap rake task that occurs at 4am'"

# ----- Modify the environment files ------------------------------------------------------------------

puts
say_status  'Config', 'Modifying the environment files...', :yellow
puts        '-'*80, ''; sleep 0.25

file 'config/environments/staging.rb', <<-CODE
require_relative 'production.rb'

#{app_name_class}::Application.configure do
  # Overwrite any production settings here, or if you want to start from scratch then remove line 1.
end
CODE

git add:    '-A'
git commit: "-m 'Add add staging environment'"

inject_into_file 'config/environments/production.rb', after: "config.log_level = :info\n" do <<-"CODE"
  config.logger = Logger.new(config.paths['log'].first, 'daily')
CODE
end

inject_into_file 'config/environments/production.rb', after: "%w( search.js )\n" do <<-"CODE"
  config.assets.precompile << Proc.new { |path|
    if path =~ /\.(eot|svg|ttf|woff|png)\z/
      true
    end
  }
CODE
end

git add:    '-A'
git commit: "-m 'Change production config options'"

# ----- Modify the initializer files ------------------------------------------------------------------

puts
say_status  'config', 'Modifying the initializer files...', :yellow
puts        '-'*80, ''; sleep 0.25

file 'config/initializers/sidekiq.rb', <<-'CODE'
ENV['CACHE_PASSWORD'].present? ? pass_string = ":#{ENV['CACHE_PASSWORD']}@" :  pass_string = ''

redis_host = "#{pass_string}#{ENV['CACHE_HOST']}"

sidekiq_config = {
  url: "redis://#{redis_host}:#{ENV['CACHE_PORT']}/#{ENV['CACHE_DATABASE']}",
  namespace: "ns_app::sidekiq_#{Rails.env}"
}

Sidekiq.configure_server do |config|
  config.redis = sidekiq_config
end

Sidekiq.configure_client do |config|
  config.redis = sidekiq_config
end
CODE

gsub_file 'config/initializers/sidekiq.rb', 'ns_app', app_name

git add:    '-A'
git commit: "-m 'Add the sidekiq initializer'"

file 'config/initializers/mini_profiler.rb', <<-CODE
if defined? Rack::MiniProfiler
  # Toggle with ALT+p
  Rack::MiniProfiler.config.start_hidden = true
end
CODE

git add:    '-A'
git commit: "-m 'Add the rack mini profiler initializer'"

# ----- Modify the routes file ------------------------------------------------------------------------

puts
say_status  'config', 'Modifying the routes file...', :yellow
puts        '-'*80, ''; sleep 0.25

prepend_file 'config/routes.rb', "require 'sidekiq/web'\n\n"

git add:    '-A'
git commit: "-m 'Add sidekiq to the routes file'"

inject_into_file 'config/routes.rb', after: "draw do\n" do <<-CODE
  concern :pageable do
    get 'page/:page', action: :index, on: :collection
  end
CODE
end

git add:    '-A'
git commit: "-m 'Add a route concern for pagination'"

# ----- Creating application tasks --------------------------------------------------------------------

puts
say_status  'tasks', 'Creating application tasks...', :yellow
puts        '-'*80, ''; sleep 0.25

file 'lib/tasks/orats/favicon.rake', <<-'CODE'
namespace :orats do
  desc 'Create favicons from a single base png'
  task :favicons do
    require 'favicon_maker'

    FaviconMaker.generate do
      setup do
        template_dir Rails.root.join('app', 'assets', 'favicon')
        output_dir Rails.root.join('public')
      end

      favicon_base_path = "#{template_dir}/favicon_base.png"

      unless File.exist?(favicon_base_path)
        puts
        puts 'A base favicon could not be found, make sure one exists at:'
        puts base_favicon
        puts
        exit 1
      end

      from File.basename(favicon_base_path) do
        icon 'speeddial-160x160.png'
        icon 'apple-touch-icon-228x228-precomposed.png'
        icon 'apple-touch-icon-152x152-precomposed.png'
        icon 'apple-touch-icon-144x144-precomposed.png'
        icon 'apple-touch-icon-120x120-precomposed.png'
        icon 'apple-touch-icon-114x114-precomposed.png'
        icon 'apple-touch-icon-76x76-precomposed.png'
        icon 'apple-touch-icon-72x72-precomposed.png'
        icon 'apple-touch-icon-60x60-precomposed.png'
        icon 'apple-touch-icon-57x57-precomposed.png'
        icon 'favicon-196x196.png'
        icon 'favicon-160x160.png'
        icon 'favicon-96x96.png'
        icon 'favicon-64x64.png'
        icon 'favicon-32x32.png'
        icon 'favicon-24x24.png'
        icon 'favicon-16x16.png'
        icon 'favicon.ico', size: '64x64,32x32,24x24,16x16'
      end

      each_icon do |filepath|
        puts "Creating favicon for: #{File.basename filepath}"
      end
    end
  end
end
CODE

git add:    '-A'
git commit: "-m 'Add a favicon generator task'"

file 'lib/tasks/orats/backup.rake', <<-'CODE'
namespace :orats do
  desc 'Create a backup of your application for a specific environment'
  task backup: :environment do
    # hack'ish way to run the backup command with elevated privileges, it won't prompt for a password on the production
    # server because passwordless sudo has been enabled if you use the ansible setup provided by orats
    system 'sudo whoami'

    system "backup perform -t backup -c '#{Rails.root.join('lib', 'backup', 'config.rb')}' --log-path='#{Rails.root.join('log')}'"
  end
end
CODE

git add:    '-A'
git commit: "-m 'Add a backup task'"

# ----- Creating application backup --------------------------------------------------------------------

puts
say_status  'backup', 'Creating application backup script...', :yellow
puts        '-'*80, ''; sleep 0.25

file 'lib/backup/config.rb', <<-'CODE'
##
# Backup v4.x Configuration
#
# Documentation: http://meskyanichi.github.io/backup
# Issue Tracker: https://github.com/meskyanichi/backup/issues

##
# Config Options
#
# The options here may be overridden on the command line, but the result
# will depend on the use of --root-path on the command line.
#
# If --root-path is used on the command line, then all paths set here
# will be overridden. If a path (like --tmp-path) is not given along with
# --root-path, that path will use it's default location _relative to --root-path_.
#
# If --root-path is not used on the command line, a path option (like --tmp-path)
# given on the command line will override the tmp_path set here, but all other
# paths set here will be used.
#
# Note that relative paths given on the command line without --root-path
# are relative to the current directory. The root_path set here only applies
# to relative paths set here.
#
# ---
#
# Sets the root path for all relative paths, including default paths.
# May be an absolute path, or relative to the current working directory.
#

root_path 'lib/backup'

#
# Sets the path where backups are processed until they're stored.
# This must have enough free space to hold apx. 2 backups.
# May be an absolute path, or relative to the current directory or +root_path+.
#

tmp_path  '../../tmp'

#
# Sets the path where backup stores persistent information.
# When Backup's Cycler is used, small YAML files are stored here.
# May be an absolute path, or relative to the current directory or +root_path+.
#

data_path '../../tmp/backup/data'

##
# Utilities
#
# If you need to use a utility other than the one Backup detects,
# or a utility can not be found in your $PATH.
#
#   Utilities.configure do
#     tar       '/usr/bin/gnutar'
#     redis_cli '/opt/redis/redis-cli'
#   end

##
# Logging
#
# Logging options may be set on the command line, but certain settings
# may only be configured here.
#
#   Logger.configure do
#     console.quiet     = true            # Same as command line: --quiet
#     logfile.max_bytes = 2_000_000       # Default: 500_000
#     syslog.enabled    = true            # Same as command line: --syslog
#     syslog.ident      = 'my_app_backup' # Default: 'backup'
#   end
#
# Command line options will override those set here.
# For example, the following would override the example settings above
# to disable syslog and enable console output.
#   backup perform --trigger my_backup --no-syslog --no-quiet

##
# Component Defaults
#
# Set default options to be applied to components in all models.
# Options set within a model will override those set here.
#
#   Storage::S3.defaults do |s3|
#     s3.access_key_id     = "my_access_key_id"
#     s3.secret_access_key = "my_secret_access_key"
#   end
#
#   Notifier::Mail.defaults do |mail|
#     mail.from                 = 'sender@email.com'
#     mail.to                   = 'receiver@email.com'
#     mail.address              = 'smtp.gmail.com'
#     mail.port                 = 587
#     mail.domain               = 'your.host.name'
#     mail.user_name            = 'sender@email.com'
#     mail.password             = 'my_password'
#     mail.authentication       = 'plain'
#     mail.encryption           = :starttls
#   end

##
# Preconfigured Models
#
# Create custom models with preconfigured components.
# Components added within the model definition will
# +add to+ the preconfigured components.
#
#   preconfigure 'MyModel' do
#     archive :user_pictures do |archive|
#       archive.add '~/pictures'
#     end
#
#     notify_by Mail do |mail|
#       mail.to = 'admin@email.com'
#     end
#   end
#
#   MyModel.new(:john_smith, 'John Smith Backup') do
#     archive :user_music do |archive|
#       archive.add '~/music'
#     end
#
#     notify_by Mail do |mail|
#       mail.to = 'john.smith@email.com'
#     end
#   end
CODE

git add:    '-A'
git commit: "-m 'Add backup config'"

file 'lib/backup/models/backup.rb', <<-'CODE'
Model.new(:backup, 'Backup for the current RAILS_ENV') do
  split_into_chunks_of 10
  compress_with Gzip

  database PostgreSQL do |db|
    db.sudo_user          = ENV['DATABASE_USERNAME']

    # To dump all databases, set `db.name = :all` (or leave blank)
    db.name               = ENV['DATABASE_NAME']
    db.username           = ENV['DATABASE_USERNAME']
    db.password           = ENV['DATABASE_PASSWORD']
    db.host               = ENV['DATABASE_HOST']
    db.port               = 5432
    db.socket             = '/var/run/postgresql'
    #db.skip_tables        = ['skip', 'these', 'tables']
    #db.only_tables        = ['only', 'these', 'tables']
  end

  # uncomment the block below to archive a specific path
  # this may be useful if you have user supplied content

  # archive :app_archive do |archive|
  #   archive.add File.join(ENV['PROJECT_PATH'], 'public', 'system')
  # end

  # uncomment the block below and fill in the required information
  # to use S3 to store your backups

  # don't want to use S3? check out the other available options:
  # http://meskyanichi.github.io/backup/v4/storages/

  # store_with S3 do |s3|
  #   s3.access_key_id = ENV['S3_ACCESS_KEY_ID']
  #   s3.secret_access_key = ENV['S3_SECRET_ACCESS_KEY']
  #   s3.region = ENV['S3_REGION']
  #   s3.bucket = 'backup'
  #   s3.path = "/database/#{ENV['RAILS_ENV']}"
  # end

  ENV['SMTP_ENCRYPTION'].empty? ? mail_encryption = 'none' : mail_encryption = ENV['SMTP_ENCRYPTION']

  notify_by Mail do |mail|
    mail.on_success           = false
    #mail.on_warning           = true
    mail.on_failure           = true

    mail.from                 = ENV['ACTION_MAILER_DEFAULT_FROM']
    mail.to                   = ENV['ACTION_MAILER_DEFAULT_TO']
    mail.address              = ENV['SMTP_ADDRESS']
    mail.port                 = ENV['SMTP_PORT'].to_i
    mail.domain               = ENV['SMTP_DOMAIN']
    mail.user_name            = ENV['SMTP_USERNAME']
    mail.password             = ENV['SMTP_PASSWORD']
    mail.authentication       = ENV['SMTP_AUTH']
    mail.encryption           = mail_encryption.to_sym
  end
end
CODE

git add:    '-A'
git commit: "-m 'Add backup model'"

# ----- Creating application helpers ------------------------------------------------------------------

puts
say_status  'helpers', 'Creating application helpers...', :yellow
puts        '-'*80, ''; sleep 0.25

inject_into_file 'app/helpers/application_helper.rb', after: "ApplicationHelper\n" do <<-CODE
  def title(page_title)
    content_for(:title) { page_title }
  end

  def meta_description(page_meta_description)
    content_for(:meta_description) { page_meta_description }
  end

  def heading(page_heading)
    content_for(:heading) { page_heading }
  end

  def link_to_all_favicons
    '<link href="speeddial-160x160.png" rel="icon" type="image/png" />
    <link href="apple-touch-icon-228x228-precomposed.png" rel="apple-touch-icon-precomposed" sizes="228x228" type="image/png" />
    <link href="apple-touch-icon-152x152-precomposed.png" rel="apple-touch-icon-precomposed" sizes="152x152" type="image/png" />
    <link href="apple-touch-icon-144x144-precomposed.png" rel="apple-touch-icon-precomposed" sizes="144x144" type="image/png" />
    <link href="apple-touch-icon-120x120-precomposed.png" rel="apple-touch-icon-precomposed" sizes="120x120" type="image/png" />
    <link href="apple-touch-icon-114x114-precomposed.png" rel="apple-touch-icon-precomposed" sizes="114x114" type="image/png" />
    <link href="apple-touch-icon-76x76-precomposed.png" rel="apple-touch-icon-precomposed" sizes="76x76" type="image/png" />
    <link href="apple-touch-icon-72x72-precomposed.png" rel="apple-touch-icon-precomposed" sizes="72x72" type="image/png" />
    <link href="apple-touch-icon-60x60-precomposed.png" rel="apple-touch-icon-precomposed" sizes="60x60" type="image/png" />
    <link href="apple-touch-icon-57x57-precomposed.png" rel="apple-touch-icon-precomposed" sizes="57x57" type="image/png" />
    <link href="favicon-196x196.png" rel="icon" sizes="196x196" type="image/png" />
    <link href="favicon-160x160.png" rel="icon" sizes="160x160" type="image/png" />
    <link href="favicon-96x96.png" rel="icon" sizes="96x96" type="image/png" />
    <link href="favicon-64x64.png" rel="icon" sizes="64x64" type="image/png" />
    <link href="favicon-32x32.png" rel="icon" sizes="32x32" type="image/png" />
    <link href="favicon-24x24.png" rel="icon" sizes="24x24" type="image/png" />
    <link href="favicon-16x16.png" rel="icon" sizes="16x16" type="image/png" />
    <link href="favicon.ico" rel="icon" type="image/x-icon" />
    <link href="favicon.ico" rel="shortcut icon" type="image/x-icon" />'.html_safe
  end

  def humanize_boolean(input)
    input ||= ''

    case input.to_s.downcase
    when 't', 'true'
      'Yes'
    else
      'No'
    end
  end

  def css_for_boolean(input)
    if input
      'success'
    else
      'danger'
    end
  end
CODE
end

git add:    '-A'
git commit: "-m 'Add favicon and boolean view helpers'"

# ----- Creating view files ---------------------------------------------------------------------------

puts
say_status  'views', 'Creating view files...', :yellow
puts        '-'*80, ''; sleep 0.25

run 'rm -f app/views/layouts/application.html.erb'

file 'app/views/layouts/application.html.erb', <<-HTML
<!doctype html>
<html lang="en">
  <head>
  <title><%= yield :title %></title>
  <meta charset="utf-8" />
  <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="<%= yield :meta_description %>" />
  <%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track' => true %>
  <%= javascript_include_tag '//ajax.googleapis.com/ajax/libs/jquery/1.10.2/jquery.min.js', 'application', 'data-turbolinks-track' => true %>
  <%= csrf_meta_tags %>
  <%= link_to_all_favicons %>
  <!--[if lt IE 9]>
    <script src="//cdnjs.cloudflare.com/ajax/libs/html5shiv/3.7/html5shiv.js"></script>
    <script src="//cdnjs.cloudflare.com/ajax/libs/json3/3.3.0/json3.min.js"></script>
    <script src="//cdnjs.cloudflare.com/ajax/libs/respond.js/1.4.2/respond.js"></script>
  <![endif]-->
  <%= render 'layouts/google_analytics_snippet' %>
</head>
<body>
  <%= render 'layouts/google_analytics_tracker' %>
  <header>
    <%= render 'layouts/navigation' %>
  </header>

  <main role="main" class="container">
    <div class="page-header">
      <h1><%= yield :heading %></h1>
    </div>
    <h4>Using disqus</h4>
    <p>Disqus related html and javascript will only be loaded when the short name is not empty.</p>
    <ul>
      <li>Set the <code>DISQUS_SHORT_NAME</code> env variable in <code>.env</code> and restart the server</li>
      <li>
        To output the main comments (place this where you want it):
        <ul><li>&lt;%= render 'layouts/disqus_comments_snippet' %&gt;</li></ul>
      </li>
      <li>
        <strong>(optional)</strong> The count snippet is already right before &lt;/body&gt;
        <ul>
          <li>
            <strong>(optional)</strong> Append #disqus_thread to the href attribute in your links.<br />
            This will tell Disqus which links to look up and return the comment count.<br />
            For example: <a href="http://foo.com/bar.html#disqus_thread">Link</a>.
          </li>
        </ul>
      </li>
    </ul>

    <%= render 'layouts/flash' %>
    <%= yield %>
  </main>

  <footer>
    <hr />
    <div class="container">
      <%= render 'layouts/footer' %>
    </div>
  </footer>

  <%= render 'layouts/disqus_count_snippet' %>
</body>
</html>
HTML

git add:    '-A'
git commit: "-m 'Add new layout view'"

file 'app/views/layouts/_flash.html.erb', <<-'HTML'
<% flash.each do |key, msg| %>
  <% unless key == :timedout %>
    <%= content_tag :div, class: "alert alert-dismissable alert-#{key}" do -%>
      <button type="button" class="close" data-dismiss="alert" aria-hidden="true">
        &times;
      </button>
      <%= msg %>
    <% end %>
  <% end %>
<% end %>
HTML

git add:    '-A'
git commit: "-m 'Add flash message partial'"

file 'app/views/layouts/_navigation.html.erb', <<-HTML
<nav class="navbar navbar-default">
  <div class="container">
    <div class="navbar-header">
      <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
        <span class="sr-only">Toggle navigation</span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
      </button>
      <%= link_to '#{app_name}', '#root_path_would_go_here', class: 'navbar-brand' %>
    </div>
    <div class="collapse navbar-collapse">
      <ul class="nav navbar-nav">
        <%= render 'layouts/navigation_links' %>
      </ul>
    </div>
  </div>
</nav>
HTML

git add:    '-A'
git commit: "-m 'Add navigation partial'"

file 'app/views/layouts/_navigation_links.html.erb', <<-HTML
<li class="active">
  <%= link_to 'Bar', '#' %>
</li>
HTML

git add:    '-A'
git commit: "-m 'Add navigation links partial'"

file 'app/views/layouts/_footer.html.erb', <<-HTML
<p class="text-muted">&copy; #{Time.now.year.to_s} #{app_name} - All rights reserved</p>
HTML

git add:    '-A'
git commit: "-m 'Add footer partial'"

file 'app/views/layouts/_google_analytics_snippet.html.erb', <<-HTML
<script type="text/javascript">
  var _gaq = _gaq || [];
<% if ENV['GOOGLE_ANALYTICS_UA'].present? %>
  _gaq.push(['_setAccount', '<%= ENV["GOOGLE_ANALYTICS_UA"] %>']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();
<% end %>
</script>
HTML

file 'app/views/layouts/_google_analytics_tracker.html.erb', <<-HTML
<script type="text/javascript">
  // This is added in the body to track both turbolinks and regular hits.
  _gaq.push(['_trackPageview']);
</script>
HTML

git add:    '-A'
git commit: "-m 'Add google analytics partials'"

file 'app/views/layouts/_disqus_comments_snippet.html.erb', <<-HTML
<% if ENV['DISQUS_SHORT_NAME'].present? %>
<div id="disqus_thread"></div>
<script type="text/javascript">
    var disqus_shortname = '<%= ENV["DISQUS_SHORT_NAME"] %>';

    (function() {
        var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
        dsq.src = '//' + disqus_shortname + '.disqus.com/embed.js';
        (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
    })();
</script>
<noscript>Please enable JavaScript to view the <a href="http://disqus.com/?ref_noscript">comments powered by Disqus.</a></noscript>
<a href="http://disqus.com" class="dsq-brlink">comments powered by <span class="logo-disqus">Disqus</span></a>
<% end %>
HTML

file 'app/views/layouts/_disqus_count_snippet.html.erb', <<-HTML
<% if ENV['DISQUS_SHORT_NAME'].present? %>
<div id="disqus_thread"></div>
<script type="text/javascript">
    var disqus_shortname = '<%= ENV["DISQUS_SHORT_NAME"] %>';

    (function () {
        var s = document.createElement('script'); s.async = true;
        s.type = 'text/javascript';
        s.src = '//' + disqus_shortname + '.disqus.com/count.js';
        (document.getElementsByTagName('HEAD')[0] || document.getElementsByTagName('BODY')[0]).appendChild(s);
    }());
<% end %>
HTML

git add:    '-A'
git commit: "-m 'Add disqus partials'"

# ----- Creating public files -------------------------------------------------------------------------

puts
say_status  'public', 'Creating public files...', :yellow
puts        '-'*80, ''; sleep 0.25

run 'rm -f public/404.html'
run 'rm -f public/422.html'
run 'rm -f public/500.html'

file 'public/404.html', <<-HTML
<!DOCTYPE html>
<html>
<head>
  <title>Error 404</title>
  <meta charset="utf-8" />
  <style>
  </style>
</head>

<body>
  <h1>Error 404</h1>
</body>
</html>
HTML

file 'public/422.html', <<-HTML
<!DOCTYPE html>
<html>
<head>
  <title>Error 422</title>
  <meta charset="utf-8" />
  <style>
  </style>
</head>

<body>
  <h1>Error 422</h1>
</body>
</html>
HTML

file 'public/500.html', <<-HTML
<!DOCTYPE html>
<html>
<head>
  <title>Error 500</title>
  <meta charset="utf-8" />
  <style>
  </style>
</head>

<body>
  <h1>Error 500</h1>
</body>
</html>
HTML

file 'public/502.html', <<-HTML
<!DOCTYPE html>
<html>
<head>
  <title>Error 502</title>
  <meta charset="utf-8" />
  <style>
  </style>
</head>

<body>
  <h1>Error 502</h1>
</body>
</html>
HTML

git add:    '-A'
git commit: "-m 'Add public 404, 422, 500 and 502 error pages'"

# ----- Modifying sass files --------------------------------------------------------------------------

puts
say_status  'assets', 'Modifying sass files...', :yellow
puts        '-'*80, ''; sleep 0.25

run 'mv app/assets/stylesheets/application.css app/assets/stylesheets/application.css.scss'

git add:    '-A'
git commit: "-m 'Rename application.css to application.scss'"
git add:    '-u'

inject_into_file 'app/assets/stylesheets/application.css.scss',
                 " *= require font-awesome\n",
                 before: " *= require_self\n"

git add:    '-A'
git commit: "-m 'Add font-awesome to the application.scss file'"

append_file 'app/assets/stylesheets/application.css.scss' do <<-SCSS

// Core variables and mixins
@import "bootstrap/variables";
@import "bootstrap/mixins";

// Reset
@import "bootstrap/normalize";
@import "bootstrap/print";

// Core CSS
@import "bootstrap/scaffolding";
@import "bootstrap/type";
@import "bootstrap/code";
@import "bootstrap/grid";
@import "bootstrap/tables";
@import "bootstrap/forms";
@import "bootstrap/buttons";

// Components
@import "bootstrap/component-animations";
// @import "bootstrap/glyphicons";
@import "bootstrap/dropdowns";
@import "bootstrap/button-groups";
@import "bootstrap/input-groups";
@import "bootstrap/navs";
@import "bootstrap/navbar";
@import "bootstrap/breadcrumbs";
@import "bootstrap/pagination";
@import "bootstrap/pager";
@import "bootstrap/labels";
@import "bootstrap/badges";
@import "bootstrap/jumbotron";
@import "bootstrap/thumbnails";
@import "bootstrap/alerts";
@import "bootstrap/progress-bars";
@import "bootstrap/media";
@import "bootstrap/list-group";
@import "bootstrap/panels";
@import "bootstrap/wells";
@import "bootstrap/close";

// Components w/ JavaScript
@import "bootstrap/modals";
@import "bootstrap/tooltip";
@import "bootstrap/popovers";
@import "bootstrap/carousel";

// Utility classes
@import "bootstrap/utilities";
@import "bootstrap/responsive-utilities";

.alert-notice {
  @extend .alert-success;
}

.alert-alert {
  @extend .alert-danger;
}

img {
  @extend .img-responsive;
  margin: 0 auto;
}

.validation-error {
  margin-top: 2px;
  color: $brand-danger;
  font-size: $font-size-small;
}
SCSS
end

# ----- Modifying javascript and coffeescript files ------------------------------------------------------------------

puts
say_status  'assets', 'Modifying javascript and coffeescript files...', :yellow
puts        '-'*80, ''; sleep 0.25

gsub_file 'app/assets/javascripts/application.js', "//= require jquery\n", ''

git add:    '-A'
git commit: "-m 'Remove jquery from the application.js file because it is loaded from a CDN'"

inject_into_file 'app/assets/javascripts/application.js',
                 "//= require jquery.turbolinks\n",
                 before: "//= require_tree .\n"

git add:    '-A'
git commit: "-m 'Add jquery-turbolinks to the application.js file'"

inject_into_file 'app/assets/javascripts/application.js', before: "//= require_tree .\n" do <<-CODE
//= require bootstrap/affix
//= require bootstrap/alert
//= require bootstrap/button
//= require bootstrap/carousel
//= require bootstrap/collapse
//= require bootstrap/dropdown
//= require bootstrap/modal
//= require bootstrap/popover
//= require bootstrap/scrollspy
//= require bootstrap/tab
//= require bootstrap/tooltip
//= require bootstrap/transition
CODE
end

git add:    '-A'
git commit: "-m 'Add bootstrap to the application.js file'"

# ----- Modifying gem file ----------------------------------------------------------------------------

puts
say_status  'root', 'Copying Gemfile...', :yellow
puts        '-'*80, ''; sleep 0.25

run 'rm -f Gemfile'
from_gem 'Gemfile', 'Gemfile'

git add:    '-A'
git commit: "-m 'Add basic gems to the Gemfile'"

# ----- Adding default favicon-------------------------------------------------------------------------

puts
say_status  'assets', 'Copying default favicon...', :yellow
puts        '-'*80, ''; sleep 0.25

base_path = "#{File.expand_path File.dirname(__FILE__)}/includes"
run 'mkdir -p app/assets/favicon'
run "cp #{base_path}/app/assets/favicon/favicon_base.png app/assets/favicon/favicon_base.png"

git add:    '-A'
git commit: "-m 'Add default 256x256 favicon'"