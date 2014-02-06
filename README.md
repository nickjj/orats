## What is orats and what problem does it solve?

It stands for opinionated rails application templates. This repository has a collection of opinionated templates
to get you up and going with a modern rails application stack.

I noticed I kept making the same changes to every single rails app I made and it actually takes quite a bit of time to
setup all of this manually each time you make an app.

It is clearly a problem that can be automated so I sat down and started to create a few templates to do just that.

## What version of Rails and Ruby are you targeting?

#### Rails 4.0.x and Ruby 2.1.0

I will be updating them as new versions come out and when the gems used are proven to work. All important gems in the Gemfile
are locked using the pessimistic operator `~>` so you can be sure that everything plays nice as long as rubygems.org is up!

## System dependencies that apply to every template

- Ruby 2.1.0
    - Yep, you really need Ruby to run Ruby modules.
- Rails 4.0.x
    - You also need Rails installed so that you can run the project generator.
- Git
    - The weapon of choice for version control.
- wget
    - To download certain files from github when you create a new project.
- Postgres
    - All of the templates use postgres as a primary persistent database.
- Redis
    - Used as a sidekiq background worker and as the rails cache back end.

## Base template

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

### Base template installation instructions

#### 1. Create the project

```
rails new myapp --skip-bundle --template \
https://raw.github.com/nickjj/orats/master/templates/base.rb
```

#### 2. Run bundle install

`cd myapp && bundle install`

This could have been done automatically for the base template however I feel like it's more general to allow users to add
or remove gems from the `Gemfile` before running `bundle install`. You might not even want a database too for whatever reasons.

#### 3. Configure the environment variables

Open the `.env` file and set the correct environment variables for your development box. It is expected
that during your server provisioning phase you will have the ENV variables on the production machine already. The `dotenv`
gem is only loaded in development and test environments.

#### 4. Prepare your database and get rails ready to go

`bundle exec rake db:create:all db:migrate db:test:prepare`

#### 5. Run the server in development mode

`bundle exec foreman start`

That should start up both a puma rails server listening on port 3000 as well as sidekiq. If you are getting errors then make sure
you have all of the system dependencies setup correctly and that you have configured the `.env` file properly.

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

## Expanding beyond the base template

**Every other template will require you to have an unmodified base template already generated.** Thor was used to create the
template files and you can go only so far with injecting text at specific regex patterns.

All of the non-base templates will also run `bundle install` automatically because they will be using generators which
require certain gems to be installed. This comes at a pretty high cost though because some people use gemsets while others
do not. Some people use rbenv while others use rvm or something else.

The templates all assume you are using bundler to handle gem separation without gemsets. If you want to send pull requests
which create an rvm/gemset version of each template I will gladly accept it as long as it's a separate template file.

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

### Authentication and authorization template installation instructions

#### 1. Create the project

```
rails new myapp --skip --skip-bundle --template \
https://raw.github.com/nickjj/orats/master/templates/authentication-and-authorization.rb
```

Notice this time instead of running `--skip-bundle` we are running both `--skip` and `--skip-bundle`. It is an important
difference as `--skip` will append the changes to the `myapp` folder rather than try to create a brand new project from scratch.

This template will run `bundle install` automatically at a specific point in the script and it will install 3 new gems. They
are devise, devise-async and pundit.

#### 2. Migrate the changes and add the seed account

`cd myapp && bundle exec rake db:migrate db:seed`

#### 3. Run the server in development mode

`bundle exec foreman start`

## Application deployment

This still has yet to be done but it will include a capistrano config setup to use puma so that you can do phased restarts
with no downtime deploys. It will likely just be a config setup so that everything is hosted on 1 server and you can
quickly put in your real information at the top of the config to get started.

## Server provisioning

I really like chef and I think at some point there might be a template which creates an application cookbook which provisions
every dependency required to setup this stack.

I don't think it will ever get too advanced because deployment is very specific to each application but it can at least
dump out a ~100 line cookbook that configures everything to get a server up and running and all you would have to do is
change the user names and setup an encrypted data bag for passwords.

I am not a chef wizard yet but I would love to move away from capistrano and use chef to manage the server and the app. If
someone wants to write this template then please do so and send me a pull request.

## What is the easiest way to nuke orats projects?

You will want to not only delete the rails project directory but you will also want to delete the postgres database
and delete the keys on your redis server. Simply execute the following commands and do not forget to replace the
word `myapp` with your real app name.

All data will be lost as this really deletes the database associated with this project, proceed with caution.

    cd myapp && bundle exec rake db:drop && cd .. && rm -rf myapp
    redis-cli KEYS "myapp:*" | xargs --delim='\n' redis-cli DEL

That second command will clear out any keys in the redis server that are associated to your application since they are
all namespaced by your app name as long as you did not change that manually.