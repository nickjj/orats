# =====================================================================================================
# Template for generating an ansible playbook
# =====================================================================================================

# ----- Helper functions and variables ----------------------------------------------------------------

require 'securerandom'

def generate_token
  SecureRandom.hex(64)
end

def git_config(field)
  command = "git config --global user.#{field}"
  git_field_value = run(command, capture: true).gsub("\n", '')
  default_value = "YOUR_#{field.upcase}"

  git_field_value.to_s.empty? ? default_value : git_field_value
end

app_name_upper = app_name.upcase
app_name_class = app_name.humanize

author_name = git_config 'name'
author_email = git_config 'email'

# ----- Nuke all of the rails code --------------------------------------------------------------------

puts
say_status  'shell', 'Removing all of the generated rails code...', :yellow
puts        '-'*80, ''; sleep 0.25

run 'rm -rf * .git .gitignore'

# ----- Create playbook -------------------------------------------------------------------------------

puts
say_status  'init', 'Creating playbook...', :yellow
puts        '-'*80, ''; sleep 0.25

run "mkdir -p #{app_name}"

# ----- Move playbook back one directory --------------------------------------------------------------

puts
say_status  'shell', 'Moving playbook back one directory...', :yellow
puts        '-'*80, ''; sleep 0.25

run "mv #{app_name}/* ."
run "rm -rf #{app_name}"

# ----- Create the git repo ---------------------------------------------------------------------------

puts
say_status  'git', 'Creating initial commit...', :yellow
puts        '-'*80, ''; sleep 0.25

git :init
git add: '.'
git commit: "-m 'Initial commit'"

# ----- Create the license ----------------------------------------------------------------------------

puts
say_status  'root', 'Creating the license', :yellow
puts        '-'*80, ''; sleep 0.25

run 'rm -rf LICENSE'

file 'LICENSE' do <<-TEXT
The MIT License (MIT)

Copyright (c) #{Time.now.year} #{author_name} <#{author_email}>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
TEXT
end

git add: '.'
git commit: "-m 'Add MIT license'"

# ----- Create the site file --------------------------------------------------------------------------

puts
say_status  'root', 'Creating the site yaml file', :yellow
puts        '-'*80, ''; sleep 0.25

file 'site.yml' do <<-TEXT
---
- name: ensure all servers are commonly configured
  hosts: all
  sudo: true

  roles:
    - { role: nickjj.user, tags: [common, user] }

- name: ensure database servers are configured
  hosts: database
  sudo: true

  roles:
    - role: nickjj.security
      tags: [database, security]
      security_ufw_ports:
        - rule: deny
          port: 80
          proto: tcp
    - { role: nickjj.postgres, tags: [database, postgres] }

- name: ensure cache servers are configured
  hosts: cache
  sudo: true

  roles:
    - role: nickjj.security
      tags: [cache, security]
      security_ufw_ports:
        - rule: deny
          port: 80
          proto: tcp
    - { role: DavidWittman.redis, tags: [cache, redis] }

- name: ensure app servers are configured
  hosts: app
  sudo: true

  roles:
    - role: nickjj.security
      tags: [app, security]
      security_ufw_ports:
        - rule: allow
          port: 80
          proto: tcp
    - { role: nickjj.ruby, tags: [app, ruby] }
    - { role: nickjj.nodejs, tags: [app, nodejs] }
    - { role: nickjj.nginx, tags: [app, nginx] }
    - { role: nickjj.rails, tags: [app, rails] }
TEXT
end

git add: '.'
git commit: "-m 'Add site.yml file'"

# ----- Installation complete message -----------------------------------------------------------------

puts
say_status  'success', "\e[1m\Everything has been setup successfully\e[0m", :cyan
puts
say_status  'question', 'Are most of your apps similar?', :yellow
say_status  'answer', 'You only need to generate one playbook and you just did', :white
say_status  'answer', 'Use the inventory in each project to customize certain things', :white
puts
say_status  'question', 'Are you new to ansible?', :yellow
say_status  'answer', 'http://docs.ansible.com/intro_getting_started.html', :white
puts        '-'*80