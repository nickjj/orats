[![Gem Version](https://badge.fury.io/rb/orats.png)](http://badge.fury.io/rb/orats)

## What is orats and what problem does it solve?

It stands for opinionated rails application templates. The templates include solving tedious tasks that you would do for most projects. It handles creating a rails application with a bunch of opinions and optionally an ansible inventory/playbook so you can and provision your servers and deploy your apps effortlessly.

## What version of Rails and Ruby are you targeting?

#### Rails 4.1.x and Ruby 2.1.x

Gems will also be updated once they are proven to work on the target rails/ruby versions. The gems are locked using the pessimistic operator `~>` to ensure your installation works over time as long as rubygems.org's API is working.

## Contents
- [System dependencies](#system-dependencies)
- [Installation](#installation)
- [Commands](#commands)
- [Templates](#templates)
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
    - [Play](#play)
        - [Try it](#try-the-play-template)
        - [Ansible roles](#ansible-roles-used)
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
    - `orats new <TARGET_PATH> --pg-password=foo`
    - Configuration:
        - Optionally takes: `--pg-location [localhost]`
        - Optionally takes: `--pg-username [postgres]`
        - Optionally takes: `--redis-location [localhost]`
        - Optionally takes: `--redis-password []`
    - Template:
        - Optionally takes: `--auth [false]`
        - Optionally takes: `--template []`
    - Project:
        - Optionally takes: `--skip-extras [false]`
        - Optionally takes: `--skip-server-start [false]`
    - Ansible:
        - Optionally takes: `--sudo-password []`
        - Optionally takes: `--skip-galaxy [false]`

- **Create an ansible playbook**:
    - `orats play <TARGET_PATH>`
    - Template:
        - Optionally takes: `--template []`

- **Delete a directory and optionally all data associated to it**:
    - `orats nuke <TARGET_PATH>`
    - Optionally takes: `--skip-data [false]`

- **Detect whether or not orats, the playbook or inventory is outdated**:
    - `orats outdated [options]`
    - Optionally takes: `--playbook []`
    - Optionally takes: `--inventory []`

## Templates

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

`orats new myapp --pg-password=foo --skip-galaxy`

#### Base FAQ

##### What is `--pg-password`?

Orats will automatically start your server (you can turn this off with a flag) and also run database migrations or generators depending on what you're doing.

In order to do this it must know your postgres location, username and password. By default it will use localhost for the *location* and *postgres* as the username but if you need to supply those values because yours are different you can use `--pg-location=foo` and `--pg-username=bar`.

##### What is `--skip-galaxy`?

By default the new command will generate ansible related files for you so that you can manage this app's "inventory". It also automatically downloads the ansible roles from the [ansible galaxy](https://galaxy.ansible.com/).

This was done to ensure each app you create has the correct ansible role version to go with it. However, if you installed ansible through apt or somewhere outside of your home directory then you will get permissions errors when it tries to download the roles.

You can fix this by supplying `--sudo-password=foo` to the above command if you know ansible is installed outside of your home directory or you can just wait while the command runs and it will prompt you for your sudo password when it gets to that point because orats will attempt to use sudo only after it fails trying to install the roles without sudo.

If you don't care about the ansible at all you could add `--skip-extras` to not generate any ansible files.

##### Does your redis server use a password?

If your redis server is configured to use a password then you must also pass in `--redis-password=foo`.

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

If you run the command with `--skip-extras` you will not get the inventory, secrets or services directory. It will just generate `myapp` at the path you specify.

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

`orats new myauthapp --auth --pg-password=foo --skip-galaxy`

#### Auth FAQ

##### What do those flags do?

You should read the [try the base template](#try-the-base-template) section to get an idea of what they do.

<a name="auth-what-do-i-need-to-configure-for-development"></a>
##### What do I need to configure for development?

You may want to change `ACTION_MAILER_DEVISE_DEFAULT_FROM` in `.env`.

<a name="auth-what-do-i-need-to-configure-for-production"></a>
##### What do I need to configure for production?

You will want to change `ACTION_MAILER_DEVISE_DEFAULT_FROM` in `inventory/group_vars/all.yml`.

### Play

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

#### Try the play template

`orats play myplaybook`

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