# =============================================================================
# template for generating an orats ansible role for ansible 1.6.x
# =============================================================================
# view the task list at the bottom of the file
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# private functions
# -----------------------------------------------------------------------------
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

def git_config(field)
  command         = "git config --global user.#{field}"
  git_field_value = run(command, capture: true).gsub("\n", '')
  default_value   = "YOUR_#{field.upcase}"

  git_field_value.to_s.empty? ? default_value : git_field_value
end

def copy_from_local_gem(source, dest = '')
  dest = source if dest.empty?

  base_path = "#{File.expand_path File.dirname(__FILE__)}/includes/role"

  run "mkdir -p #{File.dirname(dest)}" unless Dir.exist?(File.dirname(dest))
  run "cp -f #{base_path}/#{source} #{dest}"
end

# ---

def delete_generated_rails_code
  log_task __method__

  run 'rm -rf * .git .gitignore'
end

def add_role_directory
  log_task __method__

  run "mkdir -p #{app_name}"
  run "mv #{app_name}/* ."
  run "rm -rf #{app_name}"
  git :init
  git_commit 'Initial commit'
end

def add_gitignore
  log_task __method__

  copy_from_local_gem '../common/.gitignore', '.gitignore'
  git_commit 'Add .gitignore'
end

def add_main_role
  log_task __method__

  folders = %w(defaults files handlers tasks templates)

  run "mkdir #{folders.join(' ')}"

  folders.delete_if { |folder| folder == 'files' || folder == 'templates' }
  folders.each do |folder|
    run "echo '---\n# #{folder} go here' > #{folder}/main.yml"
  end
end

def add_license
  log_task __method__

  author_name  = git_config 'name'
  author_email = git_config 'email'

  copy_from_local_gem '../common/LICENSE', 'LICENSE'
  gsub_file 'LICENSE', 'Time.now.year', Time.now.year.to_s
  gsub_file 'LICENSE', 'author_name', author_name
  gsub_file 'LICENSE', 'author_email', author_email
  git_commit 'Add MIT license'
end

def add_readme
  log_task __method__

  role_info   = File.basename(app_name).split('_')
  github_user = role_info[0]
  role_name   = role_info[1]

  copy_from_local_gem 'README.md'
  gsub_file 'README.md', 'github_user', github_user
  gsub_file 'README.md', 'role_name', role_name
  git_commit 'Add readme'
end

def add_meta_information
  log_task __method__

  author_name = git_config 'name'

  copy_from_local_gem 'meta/main.yml'
  gsub_file 'meta/main.yml', 'author_name', author_name
  git_commit 'Add meta information'
end

def add_tests_and_travis
  log_task __method__

  copy_from_local_gem '.travis.yml'
  copy_from_local_gem 'tests/main.yml'
  copy_from_local_gem 'tests/inventory'
  git_commit 'Add tests and travis-ci'
end

def remove_unused_files_from_git
  log_task __method__

  git add: '-u'
  git_commit 'Remove unused files'
end

# ---

delete_generated_rails_code
add_role_directory
add_gitignore
add_main_role
add_license
add_readme
add_meta_information
add_tests_and_travis
remove_unused_files_from_git