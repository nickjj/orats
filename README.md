[![Gem Version](https://badge.fury.io/rb/orats.png)](http://badge.fury.io/rb/orats)

## What is orats and what problem does it solve?

It stands for opinionated rails application templates. The templates include solving tedious tasks that you would do for most
projects. It handles creating a rails application with a bunch of opinions and optionally an ansible playbook so you can
deploy your apps quickly.

Everything is accessed through the [orats gem](#installation).

## What version of Rails and Ruby are you targeting?

#### Rails 4.1.x and Ruby 2.1.x

I will be updating them as new versions come out and when the gems used are proven to work. All important gems in the Gemfile
are locked using the pessimistic operator `~>` so you can be sure that everything plays nice as long as rubygems.org is up!

## System dependencies that must be on your dev box

- [The orats gem](#installation)
    - To download each rails template and automate running certain tasks.
- Ruby 2.1.x
    - Yep, you really need Ruby to run Ruby modules.
- Rails 4.1.x
    - You need Rails installed so that you can run the project generator.
- Git
    - The weapon of choice for version control.
- Postgres
    - All of the templates use postgres as a primary persistent database.
- Redis
    - Used as a sidekiq background worker and as the rails cache back end.

### Additional system dependencies for ansible

`orats` is smart enough to skip trying to create ansible related files if it cannot find the necessary dependencies to successfully
use them. To successfully create ansible content you must fulfill the requirements below:

- Ansible is installed and setup in such a way that `ansible` is on your system path.

## Contents

- orats
    - [Installation](#installation)
    - [Commands](#commands)
- Templates
    - [Base](#base)
    - [Authentication and authorization](#authentication-and-authorization)
    - [Playbook](#playbook)
        - [Overview](#the-playbook-comes-with-the-following-features)
- Sections
    - [Production tweaks](#production-tweaks)

## orats

### Installation

`gem install orats`

### Commands

Here is an overview of the available commands. You can find out more information about each command and flag by simply
running `orats <command name> help` from your terminal. You can also type `orats` on its own to see a list of all commands.

- Create a new orats project
    - `orats new <APP_PATH> --pg-password <development postgres db password>`
    - Configuration:
        - Optionally takes: `--pg-location [localhost]`
        - Optionally takes: `--pg-username [postgres]`
        - Optionally takes: `--redis-location [localhost]`
        - Optionally takes: `--redis-password []`
    - Template features:
        - Optionally takes: `--auth [false]`
    - Project features:
        - Optionally takes: `--skip-extras [false]`
        - Optionally takes: `--skip-foreman-start [false]`
    - Ansible features:
        - Optionally takes: `--sudo-password []`
        - Optionally takes: `--skip-galaxy [false]`

- Create an ansible playbook
    - `orats play <PATH>`

- Delete the directory and optionally all data associated to it
    - `orats nuke <APP_PATH>`
    - Optionally takes: `--skip-data [false]`

- Detect whether or not orats, the playbook or inventory is outdated
    - `orats outdated [options]`
    - Optionally takes: `--playbook []`
    - Optionally takes: `--inventory []`

#### Why is it asking me for my development postgres password?

In order to automate certain tasks such as running database migrations the script must be able to talk to your database.
It cannot talk to your database without knowing the location, username and password for postgres. In most cases the
location will be `localhost` and the username will be `postgres` so these values are provided by default.

Remember, this is only your development postgres password. It will **never** ask for your production passwords.

#### Is the outdated detection guaranteed to be accurate?

The version comparisons can be fully trusted but when comparing a specific playbook or inventory file it's not really
possible to guarantee a valid comparison.

When passing in `--playbook` or `--inventory` it will look for certain keywords in the file. If it finds the
keyword then it will assume that keyword is working and up to date. Since you can edit these files freely there may be
cases where it reports a false positive.

It's better than nothing and it also doubles as an upgrade guide too if you wanted to add in new role lines to your
playbook file or paste in a few new variables in your inventory that exist in a newer version of orats that you planned
to update.

It will detect missing, outdated and extra keywords between your version of orats, your user generated files and the
latest version on github. Execute `orats help outdated` if you get confused.

## Base

This is the starter template that every other template will append to. I feel like when I make a new project, 95% of the time
it includes these features and when I do not want a specific thing it is much quicker to remove it than add it.

### Features that are included in the base template

- Add a few popular OS and editor files to the .gitignore file.
- Create development, staging and production environments.
- Use environment variables for things that are likely to change per environment.
- Use environment variables for anything that is sensitive and should not be included into version control.
- Use redis as the cache backend.
- Use sidekiq as a background worker.
- Use puma as the server with settings capable of doing phased restarts.
- Use foreman in development mode to manage starting both the rails server using puma and sidekiq.
- Set the production asset precompiler to include fonts and png files.
- Set the production logger to rotate the logs daily.
- Use DHH's config gem to store application wide configuration variables.
- Set the timezone to EST.
- Change how validation errors are reported by having them be displayed inline for each element.
- Dry out the `database.yml` and use postgres.
- Setup a sitemap that updates itself once a day using a cronjob managed through the `whenever` gem.
- Add a route level concern for pagination and use kaminari for pagination.
- Add a rake task which generates favicons for every popular device and a view helper to include them in your layout.
- Add 2 view helpers, `humanize_boolean` and `css_for_boolean` to nicely output true/false values and they can be changed easily.
- Add 3 view helpers to easily set a page's title, meta description and page heading. All of which are optional.
- Bootstrap ~3 layout file with conditionally loaded `html5shiv`, `json3` and `respondjs` libs for IE < 9 support.
- Separate the navigation, navigation links, flash messages, footer and google analytics snippets into partials.
- Public 404, 422, 500 and 502 pages so they can be served directly from your web server.
- Use sass and coffeescript.
- jquery 1.10.x loaded through a CDN.
- Use bootstrap ~3 and font awesome using the standard community gems.
- Rack mini profiler, bullet and meta_request support for development mode profiling and analysis.

Everything has been added with proper git commits so you have a trail of changes.

### Try it

`orats new myapp --pg-password <development postgres db password>`

Towards the end of the run you might get prompted for a sudo password if you have not skipped installing the ansible
roles from the galaxy. It will only try to use sudo if it fails with a permission error first.

You can also provide a `--sudo-password=foo` flag to set your password so orats can finish without any user input.

#### What's with the services directory?

It is just a naming convention that I like to apply, you can name it whatever you want later or remove it with a flag. My thought
process was you might have multiple services which when put together create your web application. In many cases your web
application might just be a single rails app, but maybe not.

What if you introduced a Go service to do something which your rails application talks to for a certain area of your site?
Perhaps you have 2 rails applications too. One of them for your admin app and the other for the public facing app.

Long story short the extra directory is probably worth it in the long run and it's simple to remove if you don't like it.

### All I see is the default rails page

Yes, this has been done by choice. I have no idea what your rails project is supposed to do. Rather than write in a million
questions into the template generator it expects you to dive in and start implementing your shiny new rails application.

### Production tweaks

There are a few settings you need to be aware of for when you deploy your application into production. You also need to be
aware that the `.env` file is not loaded in production, in fact it is not even sent to your server because it is in .gitignore.

You can use the `.env` file as a guide so you know which values you need to write out as true ENV variables on your server
using whatever server provisioning tools you use.

#### Project path

Make sure you have the project path set properly on your server. It is used by both puma and sidekiq to determine where
they should write out their pid, socket and log files. If this is not set correctly then you will not be able to start
your application properly in non-development mode.

#### Puma

You should set your puma min/max threads to 0 and 16 and use at least 2 workers if you want to do phased restarts. From
there you can load test your deploy and tinker as necessary.

In production mode it is expected that you will be placing your rails app behind a web server such as nginx or apache. If
you do not do this then you must open `config/puma.rb` and check out the `RAILS_ENV` conditional because by default it will
not listen on a port in production. Instead it will use a unix socket.

#### Sidekiq

Sidekiq's concurrency value is 25 by default, again experiment with what works best for you because there is no reasonable
default magic value that works for everyone.

#### Postgres

You should set the pool size to be the maximum between your puma max threads and sidekiq concurrency value but it does not
have to be exact. Feel free to experiment.

## Authentication and authorization

Authentication is extremely common but the use cases of authentication vary by a lot. You might want 3 user profile
models that have foreign keys back to a devise model while someone else might only want to add 1 field directly on the devise model.
The authentication template was designed just to give you enough to get the ball rolling on your upcoming project.

### Additional features added to the base template

- Devise for authentication.
- Devise async so that all of devise's e-mails are sent using sidekiq.
- Pundit for authorization. It seems to be gaining popularity over CanCan since ryan is MIA?
- Sensible defaults for the devise initializer file by placing all of the secrets into the `.env` file.
- Enable session timeouts and unlock strategies in the devise initializer.
- Bootstrap flavored view templates.
- A devise model called `Account` which contains a standard devise model with a `role` field added.
- `admin` and `guest` roles have been added to the `Account` model and the guest role is the default at the database level.
- An `.is?` method to determine if an account's role is equal to the role you pass in.
- The `Account` model has been enhanced to cache the `current_account` in redis so you do not have to perform a db lookup on every request.
- A basic pundit application policy has been generated.
- Alias `current_account` to `current_user` so that pundit and other potential gems will work as intended.
- Create a seed account in `db/seeds.rb` which acts as an admin, you should change these details asap.
- Toggle whether or not users can publicly register on the site and/or delete their account very easily.
- Expose a `/sidekiq` end-point which requires an admin account to access so you can view the queue details.

### Preventing users from being able to register

You can disable users from registering by taking a look at `config/routes.rb` and inspecting the comments near the top.
I feel like this is the cleanest way to disable registrations while still allowing users to edit and/or delete their account.

### Try it

`orats new myauthapp --pg-password <development postgres db password> --auth`

## Playbook

Building your application is only one piece of the puzzle. If you want to ship your application you have to host it somewhere.
You have a few options when it comes to managed hosts like Heroku but they tend to be very expensive if you fall out of
their free tier.

The playbook template creates an ansible playbook that will provision a **ubuntu 12.04 LTS server**. It can be hosted anywhere
as there are no hard requirements on any specific host.

### The playbook comes with the following features

- Security
    - Logging into the server is only possible with an SSH key.
    - fail2ban is setup.
    - ufw (firewall) is setup to block any ports not exposed by you.
    - All stack specific processes are running with less privileges than root.
- Stack specific processes that are installed and configured
    - Nginx
    - Postgres
    - Redis
- Runtimes
    - Ruby 2.1.x managed via rvm
    - Nodejs 0.10.x
- Git
    - Pull in app code from a remote repo of your choice.
- Monit and init.d
    - Both the app and sidekiq have init.d scripts and are actively monitored by monit

All of this is provided by a series of ansible roles. You may also use these roles without orats. If you want to
check out each role then here's a link to their repos:

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

All of the above roles will get installed and updated whenever you generate a `new` orats application.

### Try it

`orats play myrailsapp`

Ansible is very powerful and flexible when it comes to managing infrastructure. If most of your rails apps have a similar stack
then you can use a single playbook to run all of your apps. You can customize the details for each one by adjusting the inventory
that gets generated for each app.

### The `inventory` and `secrets` directories

When you create a new orats app you'll get both of these directories added for you automatically unless you `--skip-extras`.

**The inventory directory** contains the files to setup your host addresses as well as configure your application using
the parameters exposed by the various ansible roles.

**The secrets directory** holds all of the passwords and sensitive information such as ssh keypairs or ssl certificates. They
are not added to version control and these files will be copied to your server when you run the playbook.

#### First things first

Once you have an app generated make sure you check out the `inventory/group_vars/all.yml` file. You will want to make all
of your configuration changes there. After that is up to you. If you want to learn more about ansible then check out the
[getting started with ansible guide](http://docs.ansible.com/intro_getting_started.html).