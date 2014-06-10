# =====================================================================================================
# Template for generating an orats ansible 1.6.x playbook
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

def log_complete
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
end

def git_commit(message)
  git add: '-A'
  git commit: "-m '#{message}'"
end

def git_config(field)
  command = "git config --global user.#{field}"
  git_field_value = run(command, capture: true).gsub("\n", '')
  default_value = "YOUR_#{field.upcase}"

  git_field_value.to_s.empty? ? default_value : git_field_value
end

author_name = git_config 'name'
author_email = git_config 'email'

log_task 'Remove all of the generated rails code'
run 'rm -rf * .git .gitignore'

log_task 'Add playbook directory'
run "mkdir -p #{app_name}"
run "mv #{app_name}/* ."
run "rm -rf #{app_name}"
git :init
git_commit 'Initial commit'

log_task 'Add a licence'
run 'rm -rf LICENSE'

file 'LICENSE' do <<-S
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
S
end
git_commit 'Add MIT license'

log_task 'Add the main playbook'
file 'site.yml' do <<-S
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
    - { role: nickjj.whenever, tags: [app, rails] }
    - { role: nickjj.pumacorn, tags: [app, rails] }
    - { role: nickjj.sidekiq, tags: [app, rails] }
    - { role: nickjj.monit, tags: [app, monit] }
S
end
git_commit 'Add the main playbook'

log_task 'Remove unused files from git'
git add: '-u'
git_commit 'Remove unused files'

log_complete