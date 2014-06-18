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

def copy_from_local_gem(source, dest = '')
  dest = source if dest.empty?

  base_path = "#{File.expand_path File.dirname(__FILE__)}/includes/new/rails"

  run "mkdir -p #{File.dirname(dest)}" unless Dir.exist?(File.dirname(dest))
  run "cp -f #{base_path}/#{source} #{dest}"
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

  copy_from_local_gem 'Gemfile'
  git_commit 'Add Gemfile'
end

def copy_base_favicon
  log_task __method__

  copy_from_local_gem 'app/assets/favicon/favicon_base.png'
  git_commit 'Add a 256x256 base favicon'
end

def add_dotenv
  log_task 'add_dotenv'

  copy_from_local_gem '.env', '.env'
  gsub_file '.env', 'generate_token', generate_token
  gsub_file '.env', 'app_name', app_name
  git_commit 'Add development environment file'
end

def add_procfile
  log_task __method__

  copy_from_local_gem 'Procfile'
  git_commit 'Add Procfile'
end

def add_markdown_readme
  log_task __method__

  copy_from_local_gem 'README.md'
  git_commit 'Add markdown readme'
end

def update_app_secrets
  log_task __method__

  copy_from_local_gem 'config/secrets.yml'
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

  copy_from_local_gem 'config/database.yml'
  git_commit 'DRY out the yaml'
end

def add_puma_config
  log_task __method__

  copy_from_local_gem 'config/puma.rb'
  git_commit 'Add the puma config'
end

def add_sidekiq_config
  log_task __method__

  copy_from_local_gem 'config/sidekiq.yml'
  git_commit 'Add the sidekiq config'
end

def add_sitemap_config
  log_task __method__

  copy_from_local_gem 'config/sitemap.rb'
  gsub_file 'config/sitemap.rb', 'app_name', app_name
  git_commit 'Add the sitemap config'
end

def add_whenever_config
  log_task __method__

  copy_from_local_gem 'config/whenever.rb'
  git_commit 'Add the whenever config'
end

def add_sidekiq_initializer
  log_task __method__

  copy_from_local_gem 'config/initializers/sidekiq.rb'
  gsub_file 'config/initializers/sidekiq.rb', 'ns_app', app_name
  git_commit 'Add the sidekiq initializer'
end

def add_mini_profiler_initializer
  log_task __method__

  copy_from_local_gem 'config/initializers/mini_profiler.rb'
  git_commit 'Add the mini profiler initializer'
end

def add_staging_environment
  log_task __method__

  copy_from_local_gem 'config/environments/staging.rb'
  gsub_file 'config/environments/staging.rb', 'app_name.humanize',
            app_name.humanize
  git_commit 'Add a staging environment'
end

def update_development_environment
  log_task __method__

  inject_into_file 'config/environments/development.rb',
                   before: "\nend" do
    <<-'S'
  # Set the default generator asset engines
  config.generators.stylesheet_engine = :scss
  config.generators.javascript_engine = :coffee
    S
  end
  git_commit 'Update the default generator asset engines'
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

  gsub_file 'config/environments/production.rb',
            '# config.assets.css_compressor', 'config.assets.css_compressor'
  git_commit 'Add sass asset compression'
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

  copy_from_local_gem 'lib/backup/config.rb'
  copy_from_local_gem 'lib/backup/models/backup.rb'
  git_commit 'Add backup library'
end

def add_favicon_task
  log_task __method__

  copy_from_local_gem 'lib/tasks/orats/favicon.rake'
  git_commit 'Add a favicon generator task'
end

def add_backup_task
  log_task __method__

  copy_from_local_gem 'lib/tasks/orats/backup.rake'
  gsub_file 'lib/tasks/orats/backup.rake', 'app_name', app_name
  git_commit 'Add an application backup task'
end

def add_helpers
  log_task __method__

  copy_from_local_gem 'app/helpers/application_helper.rb'
  git_commit 'Add various helpers'
end

def add_layout
  log_task __method__

  copy_from_local_gem 'app/views/layouts/application.html.erb'
  git_commit 'Add layout'
end

def add_layout_partials
  log_task __method__

  copy_from_local_gem 'app/views/layouts/_flash.html.erb'

  copy_from_local_gem 'app/views/layouts/_navigation.html.erb'
  gsub_file 'app/views/layouts/_navigation.html.erb', 'app_name', app_name

  copy_from_local_gem 'app/views/layouts/_navigation_links.html.erb'

  copy_from_local_gem 'app/views/layouts/_footer.html.erb'
  gsub_file 'app/views/layouts/_footer.html.erb', 'Time.now.year.to_s',
            Time.now.year.to_s
  gsub_file 'app/views/layouts/_footer.html.erb', 'app_name', app_name

  copy_from_local_gem 'app/views/layouts/_google_analytics_snippet.html.erb'
  copy_from_local_gem 'app/views/layouts/_google_analytics_tracker.html.erb'

  copy_from_local_gem 'app/views/layouts/_disqus_comments_snippet.html.erb'
  copy_from_local_gem 'app/views/layouts/_disqus_count_snippet.html.erb'

  git_commit 'Add layout partials'
end

def add_http_error_pages
  log_task __method__

  copy_from_local_gem 'public/404.html'
  copy_from_local_gem 'public/422.html'
  copy_from_local_gem 'public/500.html'
  copy_from_local_gem 'public/502.html'

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
update_development_environment
update_production_environment
update_routes
add_backup_lib
add_backup_task
add_favicon_task
add_helpers
add_layout
add_layout_partials
add_http_error_pages
update_sass
update_coffeescript
remove_unused_files_from_git