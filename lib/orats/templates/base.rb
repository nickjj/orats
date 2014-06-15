require 'securerandom'

# =============================================================================
# template for generating an orats base project for rails 4.1.x
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

def copy_from_local_gem(source, dest)
  base_path           = "#{File.expand_path File.dirname(__FILE__)}/includes"
  file_name_of_source = File.basename(source)

  run "mkdir -p #{File.dirname(dest)}" if dest.present? && file_name_of_source != dest
  run "cp #{base_path}/#{source} #{dest}"
end

# ---

def initial_git_commit
  log_task __method__

  git :init
  git_commit 'Initial git commit'
end

def update_gitignore
  log_task __method__

  append_to_file '.gitignore' do
    <<-S
# OS and editor files
.DS_Store
*/**.DS_Store
._*
.*.sw*
*~
.idea/

# the dotenv file
.env

# app specific folders
/vendor/bundle
/public/assets/*
    S
  end
  git_commit 'Add common OS files, editor files and other paths'
end

def copy_gemfile
  log_task __method__

  run 'rm -f Gemfile'
  copy_from_local_gem 'Gemfile', 'Gemfile'
  git_commit 'Add Gemfile'
end

def copy_base_favicon
  log_task __method__

  copy_from_local_gem 'app/assets/favicon/favicon_base.png',
                      'app/assets/favicon/favicon_base.png'
  git_commit 'Add a 256x256 base favicon'
end

def add_dotenv
  log_task 'add_dotenv'

  file '.env' do
    <<-S
RAILS_ENV: development

PROJECT_PATH: /full/path/to/your/project
TIME_ZONE: Eastern Time (US & Canada)
DEFAULT_LOCALE: en

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
    S
  end
  git_commit 'Add development environment file'
end

def add_procfile
  log_task __method__

  file 'Procfile' do
    <<-S
web: puma -C config/puma.rb | grep -v --line-buffered ' 304 -'
worker: sidekiq -C config/sidekiq.yml
log: tail -f log/development.log | grep -xv --line-buffered '^[[:space:]]*' | grep -v --line-buffered '/assets/'
    S
  end
  git_commit 'Add Procfile'
end

def add_markdown_readme
  log_task __method__

  run 'rm README.rdoc'
  file 'README.md' do
    <<-S
## Project information

This project was generated with [orats](https://github.com/nickjj/orats) vVERSION.
    S
  end
  git_commit 'Add markdown readme'
end

def update_app_secrets
  log_task __method__

  gsub_file 'config/secrets.yml', /.*\n/, ''
  append_file 'config/secrets.yml' do
    <<-S
development: &default
  secret_key_base: <%= ENV['TOKEN_RAILS_SECRET'] %>

test:
  <<: *default

staging:
  <<: *default

production:
  <<: *default
    S
  end
  git_commit 'DRY out the yaml'
end

def update_app_config
  log_task __method__

  inject_into_file 'config/application.rb', after: "automatically loaded.\n" do
    <<-S
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

    # run `bundle exec rake time:zones:all` to get a complete list of valid time zone names
    config.time_zone = ENV['TIME_ZONE'] unless ENV['TIME_ZONE'] == 'UTC'

    # http://www.loc.gov/standards/iso639-2/php/English_list.php
    config.i18n.default_locale = ENV['DEFAULT_LOCALE'] unless ENV['DEFAULT_LOCALE'] == 'en'
    S
  end

  append_file 'config/application.rb' do
    <<-'S'

ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  if html_tag =~ /\<label/
    html_tag
  else
    errors = Array(instance.error_message).join(',')
    %(#{html_tag}<p class="validation-error"> #{errors}</p>).html_safe
  end
end
    S
  end
  git_commit 'Configure the mailer/redis, update the timezone and adjust the validation output'
end

def update_database_config
  log_task __method__

  gsub_file 'config/database.yml', /.*\n/, ''
  append_file 'config/database.yml' do
    <<-S
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
    S
  end
  git_commit 'DRY out the yaml'
end

def add_puma_config
  log_task __method__

  file 'config/puma.rb', <<-'S'
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
  S
  git_commit 'Add the puma config'
end

def add_sidekiq_config
  log_task __method__

  file 'config/sidekiq.yml', <<-S
---
:pidfile: <%= ENV['PROJECT_PATH'] %>/tmp/sidekiq.pid
:concurrency: <%= ENV['SIDEKIQ_CONCURRENCY'].to_i %>
:queues:
  - default
  S
  git_commit 'Add the sidekiq config'
end

def add_sitemap_config
  log_task __method__

  file 'config/sitemap.rb', <<-'S'
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
  S
  gsub_file 'config/sitemap.rb', 'app_name', app_name
  git_commit 'Add the sitemap config'
end

def add_whenever_config
  log_task __method__

  file 'config/schedule.rb', <<-S
every 1.day, at: '3:00 am' do
  rake 'orats:backup'
end

every 1.day, at: '4:00 am' do
  rake 'sitemap:refresh'
end
  S
  git_commit 'Add the whenever config'
end

def add_sidekiq_initializer
  log_task __method__

  file 'config/initializers/sidekiq.rb', <<-'S'
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
  S
  gsub_file 'config/initializers/sidekiq.rb', 'ns_app', app_name
  git_commit 'Add the sidekiq initializer'
end

def add_mini_profiler_initializer
  log_task __method__

  file 'config/initializers/mini_profiler.rb', <<-S
if defined? Rack::MiniProfiler
  # Toggle with ALT+p
  Rack::MiniProfiler.config.start_hidden = true
end
  S
  git_commit 'Add the mini profiler initializer'
end

def add_staging_environment
  log_task __method__

  file 'config/environments/staging.rb', <<-S
require_relative 'production.rb'

#{app_name.humanize}::Application.configure do
  # Overwrite any production settings here, or if you want to start from scratch then remove line 1.
end
  S
  git_commit 'Add a staging environment'
end

def update_production_environment
  log_task __method__

  inject_into_file 'config/environments/production.rb', after: "config.log_level = :info\n" do
    <<-'S'
  config.logger = Logger.new(config.paths['log'].first, 'daily')
    S
  end
  git_commit 'Update the logger to rotate daily'

  inject_into_file 'config/environments/production.rb', after: "%w( search.js )\n" do
    <<-'S'
  config.assets.precompile << Proc.new { |path|
    if path =~ /\.(eot|svg|ttf|woff|png)\z/
      true
    end
  }
    S
  end
  git_commit 'Update the assets precompiler to include common file types'
end

def update_routes
  log_task __method__

  prepend_file 'config/routes.rb', "require 'sidekiq/web'\n\n"

  inject_into_file 'config/routes.rb', after: "draw do\n" do
    <<-S
  concern :pageable do
    get 'page/:page', action: :index, on: :collection
  end

  # you may want to protect this behind authentication
  mount Sidekiq::Web => '/sidekiq'
    S
  end
  git_commit 'Add a concern for pagination and mount sidekiq'
end

def add_backup_lib
  log_task __method__

  file 'lib/backup/config.rb', <<-'S'
##
# Backup v4.x Configuration
#
# Documentation: http://meskyanichi.github.io/backup
# Issue Tracker: https://github.com/meskyanichi/backup/issues

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

root_path 'lib/backup'

# Sets the path where backups are processed until they're stored.
# This must have enough free space to hold apx. 2 backups.
# May be an absolute path, or relative to the current directory or +root_path+.

tmp_path  '../../tmp'

# Sets the path where backup stores persistent information.
# When Backup's Cycler is used, small YAML files are stored here.
# May be an absolute path, or relative to the current directory or +root_path+.

data_path '../../tmp/backup/data'

# Utilities
#
# If you need to use a utility other than the one Backup detects,
# or a utility can not be found in your $PATH.
#
#   Utilities.configure do
#     tar       '/usr/bin/gnutar'
#     redis_cli '/opt/redis/redis-cli'
#   end

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
  S

  file 'lib/backup/models/backup.rb', <<-'S'
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
  S
  git_commit 'Add backup library'
end

def add_favicon_task
  log_task __method__

  file 'lib/tasks/orats/favicon.rake', <<-'S'
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
        puts favicon_base_path
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
        puts "Creating favicon @ #{filepath}"
      end
    end
  end
end
  S
  git_commit 'Add a favicon generator task'
end

def add_backup_task
  log_task __method__

  file 'lib/tasks/orats/backup.rake', <<-'S'
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
  S
  gsub_file 'lib/tasks/orats/backup.rake', 'app_name', app_name
  git_commit 'Add an application backup task'
end

def add_helpers
  log_task __method__

  inject_into_file 'app/helpers/application_helper.rb', after: "ApplicationHelper\n" do
    <<-S
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
    S
  end
  git_commit 'Add various helpers'
end

def add_layout
  log_task __method__

  run 'rm -f app/views/layouts/application.html.erb'
  file 'app/views/layouts/application.html.erb', <<-S
<!doctype html>
<html lang="en">
  <head>
  <title><%= yield :title %></title>
  <meta charset="utf-8" />
  <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="<%= yield :meta_description %>" />
  <%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track' => true %>
  <%= javascript_include_tag '//ajax.googleapis.com/ajax/libs/jquery/1.10.2/jquery.min.js',
                             'application', 'data-turbolinks-track' => true %>
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
  S
  git_commit 'Add layout'
end

def add_layout_partials
  log_task __method__

  file 'app/views/layouts/_flash.html.erb', <<-'S'
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
  S

  file 'app/views/layouts/_navigation.html.erb', <<-S
<nav class="navbar navbar-default">
  <div class="container">
    <div class="navbar-header">
      <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
        <span class="sr-only">Toggle navigation</span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
      </button>
      <%= link_to '#{app_name}', root_path, class: 'navbar-brand' %>
    </div>
    <div class="collapse navbar-collapse">
      <ul class="nav navbar-nav">
        <%= render 'layouts/navigation_links' %>
      </ul>
    </div>
  </div>
</nav>
  S

  file 'app/views/layouts/_navigation_links.html.erb', <<-S
<li>
  <%= link_to 'Sidekiq dashboard', '/sidekiq' %>
</li>
  S

  file 'app/views/layouts/_footer.html.erb', <<-S
<p class="text-muted">&copy; #{Time.now.year.to_s} #{app_name} - All rights reserved</p>
  S

  file 'app/views/layouts/_google_analytics_snippet.html.erb', <<-S
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
  S

  file 'app/views/layouts/_google_analytics_tracker.html.erb', <<-S
<script type="text/javascript">
  // This is added in the body to track both turbolinks and regular hits.
  _gaq.push(['_trackPageview']);
</script>
  S

  file 'app/views/layouts/_disqus_comments_snippet.html.erb', <<-S
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
<noscript>
  Please enable JavaScript to view the <a href="http://disqus.com/?ref_noscript">comments powered by Disqus.</a>
</noscript>
<a href="http://disqus.com" class="dsq-brlink">comments powered by <span class="logo-disqus">Disqus</span></a>
<% end %>
  S

  file 'app/views/layouts/_disqus_count_snippet.html.erb', <<-S
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
  S
  git_commit 'Add layout partials'
end

def add_http_error_pages
  log_task __method__

  run 'rm -f public/404.html'
  run 'rm -f public/422.html'
  run 'rm -f public/500.html'
  file 'public/404.html', <<-S
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
  S

  file 'public/422.html', <<-S
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
  S

  file 'public/500.html', <<-S
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
  S

  file 'public/502.html', <<-S
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
  S
  git_commit 'Add http status code pages'
end

def update_sass
  log_task __method__

  run 'mv app/assets/stylesheets/application.css app/assets/stylesheets/application.css.scss'
  inject_into_file 'app/assets/stylesheets/application.css.scss',
                   " *= require font-awesome\n",
                   before: " *= require_self\n"
  append_file 'app/assets/stylesheets/application.css.scss' do
    <<-S

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
}

.validation-error {
  margin-top: 2px;
  color: $brand-danger;
  font-size: $font-size-small;
}
    S
  end
  git_commit 'Add font-awesome, bootstrap and a few default styles'
end

def update_coffeescript
  log_task __method__

  gsub_file 'app/assets/javascripts/application.js', "//= require jquery\n", ''
  git_commit 'Remove jquery because it is loaded from a CDN'

  inject_into_file 'app/assets/javascripts/application.js',
                   "//= require jquery.turbolinks\n",
                   before: "//= require_tree .\n"
  inject_into_file 'app/assets/javascripts/application.js', before: "//= require_tree .\n" do
    <<-S
//= require bootstrap/affix
//= require bootstrap/alert
//= require bootstrap/button
//= require bootstrap/carousel
//= require bootstrap/collapse
//= require bootstrap/dropdown
//= require bootstrap/modal
//= require bootstrap/tooltip
//= require bootstrap/popover
//= require bootstrap/scrollspy
//= require bootstrap/tab
//= require bootstrap/transition
    S
  end
  git_commit 'Add jquery.turbolinks and bootstrap'
end

def remove_unused_files_from_git
  log_task __method__

  git add: '-u'
  git_commit 'Remove unused files'
end

# ---

initial_git_commit
update_gitignore
copy_gemfile
copy_base_favicon
add_dotenv
add_procfile
add_markdown_readme
update_app_secrets
update_app_config
update_database_config
add_puma_config
add_sidekiq_config
add_sitemap_config
add_whenever_config
add_sidekiq_initializer
add_mini_profiler_initializer
add_staging_environment
update_production_environment
update_routes
add_backup_lib
add_favicon_task
add_backup_task
add_helpers
add_layout
add_layout_partials
add_http_error_pages
update_sass
update_coffeescript
remove_unused_files_from_git