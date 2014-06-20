[![Gem Version](https://badge.fury.io/rb/orats.png)](http://badge.fury.io/rb/orats)

##### Note
This readme file is based off the master version of orats. If you want accurate documentation then make sure to select the branch for the latest *gem version* of orats.

## What is orats and what problem does it solve?

It stands for opinionated rails application templates. The templates include solving tedious tasks that you would do for most projects. It handles creating a rails application with a bunch of opinions and optionally an ansible inventory/playbook so you can and provision your servers and deploy your apps effortlessly.

## What version of Rails and Ruby are you targeting?

#### Rails 4.1.x and Ruby 2.1.x

Gems will also be updated once they are proven to work on the target rails/ruby versions. The gems are locked using the pessimistic operator `~>` to ensure your installation works over time as long as rubygems.org's API is working.

## Contents
- [System dependencies](#system-dependencies)
- [Installation](#installation)
- [Commands](#commands)
    - [Project](#project)
    - [Inventory](#inventory)
        - [Try it](#try-the-inventory-command)
        - [FAQ](#inventory-faq)
            - [What's with the sudo password](#whats-with-the-sudo-password)
    - [Playbook](#playbook)
        - [Try it](#try-the-playbook-command)
        - [Ansible roles](#ansible-roles-used)
    - [Diff](#diff)
        - [Try it](#try-the-diff-command)
    - [Templates](#templates)
        - [Try it](#try-the-templates-command)
- [Available templates](#available-templates)
    - [Base](#base)
        - [Try it](#try-the-base-template)
        - [FAQ](#base-faq)
            - [What's with the directory structure?](#whats-with-the-directory-structure)
            - [Development configuration?](#base-what-do-i-need-to-configure-for-development)
            - [Production configuration?](#base-what-do-i-need-to-configure-for-production)
    - [Auth](#auth)
        - [Try it](#try-the-auth-template)
        - [FAQ](#auth-faq)
            - [Development configuration?](#auth-what-do-i-need-to-configure-for-development)
            - [Production configuration?](#auth-what-do-i-need-to-configure-for-production)
    - [Custom](#custom)
        - [Try it](#try-the-custom-template)
        - [FAQ](#custom-faq)
            - [Any guides on how to make custom templates?](#any-guides-on-how-to-make-custom-templates)
- [Wiki](https://github.com/nickjj/orats/wiki)
    - [What to look at after making a new project](https://github.com/nickjj/orats/wiki/What-to-look-at-after-making-a-new-project)
    - [Get your application on a server](https://github.com/nickjj/orats/wiki/Get-your-application-on-a-server)

## System dependencies

Before running orats...

#### You must install

- [Git](http://git-scm.com/book/en/Getting-Started-Installing-Git)
- [Postgres](https://wiki.postgresql.org/wiki/Detailed_installation_guides)
- [Redis](http://redis.io/topics/quickstart)
- Ruby 2.1.x - [chruby](https://github.com/postmodern/chruby) | [rbenv](https://github.com/sstephenson/rbenv) | [rvm](https://rvm.io/)
- Rails 4.1.x - `gem install rails -v '~> 4.1.1'`

#### You should install

- [Ansible](http://docs.ansible.com/intro_installation.html)
    - If you plan to use the ansible features (optional)
- [Imagemagick](https://www.google.com/search?q=install+imagemagick)
    - If you want favicons to be automatically created (optional)
    
#### You need these processes to be running

- Postgres
- Redis

## Installation

`gem install orats`

Or if you already have orats then run `gem update orats` to upgrade to the latest version.

## Commands

Here is an overview of the available commands. You can find out more information about each command and flag by running  `orats help <command name>` from your terminal. You can also type `orats` on its own to see a list of all commands.

- **Create a new orats project**:
    - `orats project <TARGET_PATH> --pg-password foo`
    - Configuration:
        - Optionally takes: `--pg-location [localhost]`
        - Optionally takes: `--pg-username [postgres]`
        - Optionally takes: `--redis-location [localhost]`
        - Optionally takes: `--redis-password []`
    - Template:
        - Optionally takes: `--template []`
        - Optionally takes: `--custom []`
    - Project:
        - Optionally takes: `--skip-ansible [false]`
        - Optionally takes: `--skip-server-start [false]`
    - Ansible:
        - Optionally takes: `--sudo-password []`
        - Optionally takes: `--skip-galaxy [false]`

- **Create an ansible inventory**:
    - `orats inventory <TARGET_PATH>`
    - Configuration:
        - Optionally takes: `--sudo-password []`
        - Optionally takes: `--skip-galaxy [false]`

- **Create an ansible playbook**:
    - `orats playbook <TARGET_PATH>`
    - Template:
        - Optionally takes: `--custom []`

- **Delete a directory and optionally all data associated to it**:
    - `orats nuke <TARGET_PATH>`
    - Optionally takes: `--skip-data [false]`

- **Compare differences between orats versions**:
    - `orats diff [options]`
    - Optionally takes: `--hosts []`
    - Optionally takes: `--inventory []`
    - Optionally takes: `--playbook []`

- **Get a list of available orats templates**:
    - `orats templates`

### Project

The project command kicks off a new orats project. It will always use the 
base template and optionally allows you to provide the `--template foo` flag 
where `foo` would be an available template provided by orats.

You can also supply your own custom template which is explained in the 
[custom template](#custom) section.

Get started by checking out what the [base template](#base) provides.

### Inventory

The project command automatically creates an inventory for you but it also 
has an optional flag to skip doing it by providing `--skip-ansible`.

In case you decided to `--skip-ansible` or decided to delete your inventory 
from a really old project to let orats generate a new one for you then you can
 generate a new inventory on its own.

You may also consider using this command if you happen to use ansible but are
 not interested in the orats project because here is what it does:

#### Features

- Create an `inventory` folder
    - Create a `hosts` files
        - Populate it with a few groups used by an orats project
    - Create a `group_vars/all.yml` file
        - Populate it with a bunch of configuration for an orats project
- Create a `secrets` folder
    - Generate strong passwords for:
        - Your postgres user
        - Your redis server
        - Your mail account
    - Generate tokens for:
        - Rails
        - Devise
        - Devise pepper
    - Create a single private/public ssh keypair
        - This could be used to send to your servers
    - Create self signed ssl certificates to test/support ssl
    - Create a monit pem file for its optional http interface over ssl
- Galaxy install the roles required by an orats project
    - Optionally turned off with `--skip-galaxy`

#### Try the inventory command

`orats inventory myinventory`

#### Inventory FAQ

##### What's with the sudo password flag?

Ansible can be installed in a number of ways. A common way is to build a  package or use a package manager. When you install ansible this way it
 gets installed to `/etc/ansible`.
 
 By default ansible will download roles from the galaxy to 
 `/etc/ansible/roles` which will require sudo to write to.
 
 If you installed ansible to your home directory then orats is smart enough 
 not to use sudo. It will only try to use sudo when it detects a permission 
 error.
 
 You can also choose not to provide the `--sudo-password` flag but then you 
 will be prompted for a sudo password about 90% of the way through the 
 duration of the inventory command.

### Playbook

Building your application is only one piece of the puzzle. If you want to ship your application you have to host it somewhere. You have a few options when it comes to managed hosts like Heroku but they tend to be very expensive if you fall out of their free tier.

The playbook template creates an ansible playbook that will provision a **ubuntu 12.04 LTS server**. It can be hosted anywhere as there are no hard requirements on any specific host.

#### Server breakdown

Everything is broken up into ansible roles so you can quickly scale out horizontally or by splitting up your server groups such that your database is on a separate server than your application.

- **Security**:
    - Logging into the server is only possible with an ssh key
    - Root login is disable
    - fail2ban is setup
    - ufw (firewall) is setup to block any ports not exposed by you
    - All stack specific processes are running with less privileges than root
- **User**:
    - A single deploy user is created
- **Services and runtimes**:
    - Postgres
    - Redis
    - NodeJS
    - Ruby
- **Process management**:
    - Your rails app and sidekiq have `init.d` scripts
    - Your rails app and sidekiq are monitored using `monit`

#### Try the playbook command

`orats playbook myplaybook`

#### Ansible roles used

- `nickjj.user` https://github.com/nickjj/ansible-user
- `nickjj.security` https://github.com/nickjj/ansible-security
- `nickjj.postgres` https://github.com/nickjj/ansible-postgres
- `nickjj.ruby` https://github.com/nickjj/ansible-ruby
- `nickjj.rails` https://github.com/nickjj/ansible-rails
- `nickjj.whenever` https://github.com/nickjj/ansible-whenever
- `nickjj.pumacorn` https://github.com/nickjj/ansible-pumacorn
- `nickjj.sidekiq` https://github.com/nickjj/ansible-sidekiq
- `nickjj.monit` https://github.com/nickjj/ansible-monit
- `nickjj.nodejs` https://github.com/nickjj/ansible-nodejs
- `nickjj.nginx` https://github.com/nickjj/ansible-nginx
- `DavidWittman.redis` https://github.com/DavidWittman/ansible-redis

All of the above roles will get installed and updated whenever you generate a new orats project.

### Diff

The goal of the diff command is to provide you a way to compare your current 
orats gem to the latest orats gem. It can also compare the difference between
 the orats generated version of an inventory/playbook to an 
 inventory/playbook that you generated and have customized.
 
 This comes in handy when you want to upgrade orats and your project. 
 You will be able to see if your inventory/playbook are missing any variables
  or roles and it will also detect custom variables/roles that you have added.
   
It allows you to make 2 different types of comparisons:

#### Latest stable version of orats vs your version

When doing this type of comparison it only compares the actual files contained in the orats source code, not your generated inventory/playbook.
    
This is the type of comparison that is made when you run the `diff` command 
without any arguments. It is useful to run this from time to time to 
see if you are missing out on any new features in the latest version.

#### Your orats version vs your custom project files

If you pass in the `--hosts`, `--inventory` and/or `--playbook` flags along 
with a path to each of their files then it will compare the files contained 
in the orats source code to your custom generated inventory/playbook.

If you stick with the orats naming convention and directory structure there 
are a few quality of life enhancements. If you supply the path to the 
inventory folder it will do a comparison on both the inventory and hosts file for you. If you supply the path to a 
playbook folder it will automatically choose the `site.yml` playbook.

#### Try the diff command

`orats diff`

### Templates

Return a list of available templates to choose from.

#### Try the templates command

`orats templates`

## Available templates

### Base

This is the starter template that every other template will append to. I feel like when I make a new project, 95% of the time it includes these features and when I do not want a specific thing it is much quicker to remove it than add it.

#### Changes vs the standard rails project

All of the changes have git commits to go with them. After generating a project you can type `git reflog` to get a list of changes.

- **Core changes**:
    - Use `postgres` as the primary SQL database
    - Use `redis` as the cache backend
    - Use `puma` as the web server
    - Use `sidekiq` as a background worker
- **Features**:
    - Configure scheduled jobs and tasks using `whenever`
    - Pagination and a route concern mapped to `/page` using `kaminari`
    - Keep a sitemap up to date using `sitemap_generator`
    - Add a `pages` controller with `home` action that has points of interest
- **Rake tasks**:
    - Daily backups using `backup` and `whenever`
    - Generate favicons for many devices based off a single source png
- **Config**:
    - Extract a bunch of configuration to environment variables
    - Rewrite the database.yml and secrets.yml files to be more dry
    - Add a staging environment
    - **Development mode only**:
        - Use the `dotenv` gem to manage environment variables
        - Use `foreman` to manage the app's processes
        - Use `bullet`, `rack mini profiler` and `meta_request` for profiling/analysis
        - Set `scss`/`coffee` as the default generator engines
    - **Production mode only**:
        - Setup log rotation
        - Add popular file types to the assets precompile list
        - Compress `css`/`js` when running `rake assets:precompile`
    - Change validation errors to output inline on each element instead of a big list
- **Helpers**:
    - `title`, `meta_description`, `heading` to easily set those values per view
    - `humanize_boolean` to convert true/false into Yes/No
    - `css_for_boolean` to convert true/false into a css class success/danger
- **Views**:
    - Use `sass` and `coffeescript`
    - Use `bootstrap 3.x` and `font-awesome`
    - Add a minimal and modern layout file
    - Load `jquery` 1.10.x through a CDN
    - Conditionally load `html5shiv`, `json3` and `respondjs` for IE < 9 support
    - **Partials**:
        - Add navigation and navigation links
        - Add flash message
        - Add footer
        - Add google analytics
        - Add disqus
- **Public**:
    - Add 404, 422, 500 and 502 pages so they can be served directly from your reverse proxy
    - Add all of the favicons output by the favicon generator

#### Try the base template

`orats project myapp --pg-password foo --skip-galaxy`

#### Base FAQ

##### What is `--pg-password`?

Orats will automatically start your server (you can turn this off with a flag) and also run database migrations or generators depending on what you're doing.

In order to do this it must know your postgres location, username and password. By default it will use localhost for the *location* and *postgres* as the username but if you need to supply those values because yours are different you can use `--pg-location foo` and `--pg-username bar`.

##### What is `--skip-galaxy`?

By default the project command will generate ansible related files for you so that you can manage this app's "inventory". It also automatically downloads the ansible roles from the [ansible galaxy](https://galaxy.ansible.com/).

This was done to ensure each app you create has the correct ansible role version to go with it. However, if you installed ansible through apt or somewhere outside of your home directory then you will get permissions errors when it tries to download the roles.

You can fix this by supplying `--sudo-password foo` to the above command if you know ansible is installed outside of your home directory or you can just wait while the command runs and it will prompt you for your sudo password when it gets to that point because orats will attempt to use sudo only after it fails trying to install the roles without sudo.

If you don't care about the ansible at all you could add `--skip-ansible` to not generate any ansible files.

##### Does your redis server use a password?

If your redis server is configured to use a password then you must also pass in `--redis-password foo`.

##### What's with the directory structure?

Let's say you were to generate a new project at *~/tmp/myapp*, then you would get the following paths:

```
~/tmp/myapp/inventory
~/tmp/myapp/secrets
~/tmp/myapp/services
```

The **inventory** path contains the ansible inventory files for this project. This would be where your host addresses go along with configuration settings for this project.

The **secrets** path contains the passwords for various things as well as ssh keypairs and ssl certificates. This path should be kept out of version control. You could also go 1 extra step and encrypt this directory locally.

The **services** path contains your rails application. I like to call it services because you might have multiple services in 1 project.

If you run the command with `--skip-ansible` you will not get the inventory and services.

<a name="base-what-do-i-need-to-configure-for-development"></a>
##### What do I need to configure for development?

Pretty much everything is contained within environment variables. They are stored in the `.env` file located in the root directory of the rails application. It should be self explanatory. This file is also added to `.gitignore`.

<a name="base-what-do-i-need-to-configure-for-production"></a>
##### What do I need to configure for production?

If you are using ansible then you should open `inventory/group_vars/all.yml` and take a peek. Everything there has comments. Assuming you have everything hosted on 1 server then at minimum you will only need to change `rails_deploy_git_url` to get going.

The above variable is the repo where your code is contained. Ansible will clone that repo in an idempotent way.

You will also need to put the correct server IP(s) in `inventory/hosts`. At this point that's all you need to change to successfully provision a server. 

There are many other variables that you would likely change too such as adding your google analytics UA, S3 keys and all of the mail settings.

You may also want to tinker with the following values for performance reasons based on your server(s).

```
  DATABASE_POOL: 25

  PUMA_THREADS_MIN: 0
  PUMA_THREADS_MAX: 16

  # ensure there are always at least 2 workers so puma can properly do phased restarts
  PUMA_WORKERS: "{{ ansible_processor_cores if ansible_processor_cores > 1 else 2 }}"

  SIDEKIQ_CONCURRENCY: 25
```

### Auth

This is the auth template which gets merged into the base template. It contains a basic authentication setup using devise and pundit.

#### Changes vs the base template

All of the changes have git commits to go with them. After generating a project you can type `git reflog` to get a list of changes.

- **Core**:
    - Handle authentication with `devise`
    - Handle devise e-mails with `devise-async`
    - Handle authorization with `pundit`
    - Add `app/policies` with a basic pundit policy included
- **Config**:
    - Add devise related environment variables
    - Set the session timeout to 2 hours
    - Expire the auth token on timeout
    - Enable account locking based on failed attempts (7 tries)
    - Allow unlocking by e-mail or after 2 hours
    - Inform users of their last login attempt when failing to login
    - Add en-locale strings for authorization messages
    - Add devise queue to the sidekiq config
    - Add pundit related code to the application controller
- **Routes**:
    - Protect the `/sidekiq` end point so only logged in admins can see it
    - Enable/Disable users from publicly registering by commenting out a few lines
- **Database**:
    - Add a seed user that you should change the details of ASAP once you deploy
- **Models**:
    - Add `Account` devise model with an extra `role` field
        - Add `admin` and `guest` roles
        - Add `.is?` method to compare roles
        - Add `generate_password` method
        - Add a way to cache the `current_account`
- **Controllers**:
    - Alias `current_user` to `current_account`
    - Allow you to override devise's default sign in URL by uncommenting a few lines
- **Views**:
    - Use bootstrap for all of the devise views
    - Add authentication links to the navbar
- **Tests**:
    - Add `Account` fixtures
    - Add model tests for `Account`

#### Try the auth template

`orats project myauthapp --auth --pg-password foo --skip-galaxy`

#### Auth FAQ

##### What do those flags do?

You should read the [try the base template](#try-the-base-template) section to get an idea of what they do.

<a name="auth-what-do-i-need-to-configure-for-development"></a>
##### What do I need to configure for development?

You may want to change `ACTION_MAILER_DEVISE_DEFAULT_FROM` in `.env`.

<a name="auth-what-do-i-need-to-configure-for-production"></a>
##### What do I need to configure for production?

You will want to change `ACTION_MAILER_DEVISE_DEFAULT_FROM` in `inventory/group_vars/all.yml`.

### Custom

You can pass custom templates into both the `project` and `playbook` commands
. It works exactly like passing a custom application template to `rails new`.

Pass in a custom template by providing the `--custom` flag along with either a local path or a URL.

Here is a simple example of a custom template:

```
# /tmp/foo.rb

file 'app/components/foo.rb', <<-S
  class Foo
  end
S
```

#### Try the custom template

`orats project /tmp/customexample -p foo --custom /tmp/foo.rb`

#### Custom FAQ

<a name="any-guides-on-how-to-make-custom-templates"></a>
##### Any guides on how to make custom templates?

There's the official [rails guide on custom application templates]
(http://guides.rubyonrails.org/rails_application_templates.html).

You can also view the [orats project templates](https://github.com/nickjj/orats/tree/master/lib/orats/templates) to use as inspiration. All of 
the template files are self contained.