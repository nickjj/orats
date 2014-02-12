## What is orats and what problem does it solve?

It stands for opinionated rails application templates. The templates include solving tedious tasks that you would do for most
projects. It handles creating a rails application with a bunch of opinions and optionally a chef cookbook so you can deploy
your app quickly.

Everything is accessed through the [orats gem](#installation).

## What version of Rails and Ruby are you targeting?

#### Rails 4.0.x and Ruby 2.1.x

I will be updating them as new versions come out and when the gems used are proven to work. All important gems in the Gemfile
are locked using the pessimistic operator `~>` so you can be sure that everything plays nice as long as rubygems.org is up!

## System dependencies that you must have on your dev box

- [The orats gem](#installation)
    - To download each rails template and automate running certain tasks.
- Ruby 2.1.x
    - Yep, you really need Ruby to run Ruby modules.
- Rails 4.0.x
    - You need Rails installed so that you can run the project generator.
- Git
    - The weapon of choice for version control.
- Postgres
    - All of the templates use postgres as a primary persistent database.
- Redis
    - Used as a sidekiq background worker and as the rails cache back end.

### Additional system dependencies for creating cookbooks

`orats` is smart enough to skip trying to create a cookbook if it cannot find the necessary dependencies to successfully
create the cookbook, but to successfully create a cookbook you must fulfil the requirements below:

- Chef is installed and setup in such a way that `knife` is on your system path.
- Berkshelf has been gem installed and you can run `berks` from anywhere.

Not sure what chef or berkshelf is? No problem, learn about chef from these resources:

- [Learn chef course](https://learnchef.opscode.com/)
- [Berkshelf readme](http://www.berkshelf.com/)
- [Berkshelf tutorial series](http://misheska.com/blog/2013/06/16/getting-started-writing-chef-cookbooks-the-berkshelf-way/)

## Contents

- orats
    - [Installation](#installation)
    - [Commands](#commands)
- Templates
    - [Base](#base)
    - [Authentication and authorization](#authentication-and-authorization)
    - [Cookbook](#cookbook)
        - [Overview](#the-cookbook-comes-with-the-following-features)
- Sections
    - [Production tweaks](#production-tweaks)
- Wikis
    - [Chef walk through](https://github.com/nickjj/orats/wiki/Chef-walk-through)

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
    - Template features:
        - Optionally takes: `--auth [false]`
    - Project features:
        - Optionally takes: `--skip-cook [false]`
        - Optionally takes: `--skip-extras [false]`

- Create a stand alone chef cookbook
    - `orats cook <APP_PATH>`

- Delete the directory and optionally all data associated to it
    - `orats nuke <APP_PATH>`
    - Optionally takes: `--skip-data [false]`

#### Why is it asking me for my development postgres password?

In order to automate certain tasks such as running database migrations the script must be able to talk to your database.
It cannot talk to your database without knowing the location, username and password for postgres. In most cases the
location will be `localhost` and the username will be `postgres` so these values are provided by default.

Remember, this is only your development postgres password. It will **never** ask for your production passwords.

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

`orats new myapp --pg-password <development postgres db password> -C`

*We are running the command with `-C` to ignore creating a cookbook so the installation is faster.*

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

`orats new myauthapp --pg-password <development postgres db password> --auth -C`

*We are running the command with `-C` to ignore creating a cookbook so the installation is faster.*

## Cookbook

Building your application is only one piece of the puzzle. If you want to ship your application you have to host it somewhere.
You have a few options when it comes to managed hosts like Heroku but they tend to be very expensive if you fall out of
their free tier.

The cookbook template creates a chef cookbook that will provision a **ubuntu 12.04 LTS server**. It can be hosted anywhere
as there are no hard requirements on any specific host. Chef is a server management framework. This template uses the
application cookbook pattern and depends on Berkshelf. Berkshelf is very similar to bundler but for chef cookbooks.

### The cookbook comes with the following features

- Security
    - A random username is generated each time you generate a new cookbook.
    - A random ssh port is generated each time you generate a new cookbook.
    - Logging into the server is only possible with an SSH key.
    - fail2ban is setup.
    - ufw (firewall) is setup to block any ports not exposed.
    - All stack specific processes are running with less privileges than root.
- Stack specific processes that are installed and configured
    - Nginx
    - Postgres
    - Redis
- Runtimes
    - Ruby 2.1.0 managed via rvm
    - Nodejs 0.10.x
- Utils and features
    - htop for emergency live monitoring
    - logrotate with log rotation setup for anything that needs it.
    - git
    - A git repo in the deploy user's home directory which you can push to.

### Cookbook structure

It is broken up into 5 recipes:

- Base
- Database
- Cache
- Web
- Default

With the application style cookbook pattern it is a good idea to only run one recipe on your node. The default recipe
just composes the other 4 together. This makes it trivial to break out past one node in the future. If you wanted to
put your web server on server A and the database/cache servers on server B all you would have to do is create a new recipe
called something like `database_cache` (the name is arbitrary) and pull in both the database and cache recipes.

Then when you bootstrap the node you can tell it to use the new `database_cache` recipe. Awesome right? Yeah I know, chef rocks.

### Try it

`orats new mychefapp --pg-password <development postgres db password>`

#### Why is the cookbooks directory plural?

It is not uncommon for some projects to have multiple cookbooks. Of course that is completely out of scope for orats but
at least it generates a directory structure capable of sustaining multiple cookbooks.

### Tweakable attributes and meta data

You can quickly tweak a bunch of values by investigating the `attributes/default.rb` file. The values here are used in each
recipe. They are also namespaced to match the recipe file that uses them.

It is important that you change all of these values to match your setup. The only non-obvious one might be the SSH key. You
should use the key inside of your `.ssh/id_rsa.pub` file. It is the key that ends with your work station's username@hostname. Make
sure you do not include the trailing line break too.

You should also edit the details in the `metadata.rb` file.

### Encrypted values

Chef has this notion of encrypted data bags. They are used to protect sensitive information like passwords or secret tokens.
You can check out the `data_bags/<app_name>_secrets/production.json` file to know which fields you need to fill out later.

Please keep in mind that you should never input your real passwords/etc. in this file, it is only here to remind you which
settings are in your bag. This file is checked into version control. We will cover setting up the data bag with your real
information in [chef walk through on the wiki](https://github.com/nickjj/orats/wiki/Chef-walk-through).

### Workflow for customizing the cookbook

This cookbook is designed to be a generic base to get you started. It is highly encouraged to change the cookbook to suite your
exact needs. A typical workflow for making changes to the cookbook is this:

- Edit any files that you want to change.
- Bump the version in the `metadata.rb` file. *Never forget to do this step!*
- Run `berks upload` which sends the cookbooks up to your hosted chef server.

If you need to add new cookbooks then add them to `metadata.rb` and run `berks install`. If you need to pull in a cookbook
from a git repo or your local file system then put them in your `Berksfile` and also place them in `metadata.rb`. Check the
berkshelf documentation for more details.

#### Applying the cookbook changes on your server

This step is highly dependent but you have a few options. The first option is to ssh into your node and run `sudo chef-client`.
Replace ssh with capistrano if you want but the idea is the same. You would be manually invoking the `chef-client` command
which tells your node to contact the hosted chef server and pull in the changes.

The second option would be to setup a cronjob to run `chef-client` automatically at whatever interval you want. By default
I did not include this because by default chef does not do this.

Chef is idempotent so it will not re-run tasks that result in nothing changing so feel free to make changes whenever you
see fit.

### The server is up but how do I deploy my application?

This is another area where there are many options. You could use capistrano but you could also have chef manage the application
deployment too. I have a few old capistrano 2.x scripts that work fine and I really do not have any intentions of porting
them over to capistrano 3 scripts so they can be included as an orats template because I do not want to use capistrano anymore.

I'm calling out to the community for help. Can a chef expert please leverage the `deploy` or `application` resources
and provide us with a well documented solution to deploy a rails application with chef? Complete with runit scripts for
ensuring puma and sidekiq are always running of course.

### Walk through

If you have very little chef experience and want to go through the steps of creating a new orats project with a cookbook,
pushing it to a free managed chef server solution and bootstrapping a server on a local virtual machine then check out the
[chef walk through on the wiki](https://github.com/nickjj/orats/wiki/Chef-walk-through).
