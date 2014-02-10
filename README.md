## What is orats and what problem does it solve?

It stands for opinionated rails application templates. This repository has a collection of opinionated templates
to get you up and going with a modern rails application stack. They are accessed through the [orats gem](#installation).

I noticed I kept making the same changes to every single rails app I made and it actually takes quite a bit of time to
setup all of this manually each time you make an app.

It is clearly a problem that can be automated so I sat down and started to create a few templates to do just that.

## What version of Rails and Ruby are you targeting?

#### Rails 4.0.x and Ruby 2.1.x

I will be updating them as new versions come out and when the gems used are proven to work. All important gems in the Gemfile
are locked using the pessimistic operator `~>` so you can be sure that everything plays nice as long as rubygems.org is up!

## System dependencies that apply to every template

- [The orats gem](#installation)
    - To download each rails template and automate running certain tasks.
- Ruby 2.1.x
    - Yep, you really need Ruby to run Ruby modules.
- Rails 4.0.x
    - You also need Rails installed so that you can run the project generator.
- Git
    - The weapon of choice for version control.
- Postgres
    - All of the templates use postgres as a primary persistent database.
- Redis
    - Used as a sidekiq background worker and as the rails cache back end.

## Contents

- orats
    - [Installation](#installation)
    - [Commands](#commands)
- Templates
    - [Base](#base-template)
    - [Authentication and authorization](#authentication-and-authorization)
    - [Application deployment](#application-deployment)
    - [Server provisioning](#server-provisioning)
- Sections
    - [Expanding beyond the base template](#expanding-beyond-the-base-template)
    - [Production tweaks](#production-tweaks)

## orats

### Installation

`gem install orats`


### Commands

#### Application tasks

- Create a new rails application using the base template.
    - `orats base <app name> --postgres-password <insert your development postgres db password>`
    - Optionally takes `--postgres-location [localhost]`
    - Optionally takes `--postgres-username [postgres]`

- Create a new rails application with authentication/authorization.
    - `orats auth <app name> --postgres-password <insert your development postgres db password>`
    - Optionally takes `--postgres-location [localhost]`
    - Optionally takes `--postgres-username [postgres]`

- Delete an application and optionally its postgres databases and redis namespace.
    - `orats nuke <app name>`
    - Optionally takes `--delete-data [true]`

#### Why is it asking me for my development postgres password?

The password is it asking for is only for your development database. It will **never** ask for your production passwords.

In order to automate certain tasks such as running database migrations the script must be able to talk to your database.
It cannot talk to your database without knowing the location, username and password for postgres. In most cases the
location will be `localhost` and the username will be `postgres` so these values are provided by default.

If you are curious about the implementation details feel free to [take a look](https://github.com/nickjj/orats/blob/master/orats.thor#L127).

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

### Try it

`orats base myapp --postgres-password <development postgres db password>`

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

`orats auth myapp --postgres-password <development postgres db password>`

## Server provisioning

I really like chef and I think at some point there might be a template which creates an application cookbook which provisions
every dependency required to setup this stack using **ubuntu server 12.04 LTS**.

I don't think it will ever get too advanced because deployment is very specific to each application but it can at least
dump out a ~200 line cookbook that configures everything to get a server up and running and all you would have to do is
change a few settings in the chef attributes file and setup an encrypted data bag like usual.

Right now I have a template in the works that will get you from an empty ubuntu server to a fully working server that
can do everything but handle deploying your rails application. Normally I use capistrano to deploy my app but I want to
move away from that and let chef handle it but I do not have the chef chops to do this yet. I will gladly accept any pull
requests to add this functionality in.