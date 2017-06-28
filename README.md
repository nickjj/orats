[![Gem Version](https://badge.fury.io/rb/orats.png)](http://badge.fury.io/rb/orats) [![Build Status](https://secure.travis-ci.org/nickjj/orats.png)](http://travis-ci.org/nickjj/orats)

## What is orats?

It stands for opinionated rails application templates.

The goal is to provide you an excellent base application that you can use on
your next Rails project.

You're meant to generate a project using orats and then build your custom
application on top of it.

It also happens to use Docker so that your app can be ran on any major
platform -- even without needing Ruby installed.

If you want to learn about Docker specifically then I recommend checking out
[Dive Into Docker: The Complete Docker Course for Developers](https://diveintodocker.com/courses/dive-into-docker?utm_source=orats&utm_medium=github&utm_campaign=readmetop).

## What versions are you targeting?

#### Ruby 2.4+

#### Rails 5.1+

#### Docker 1.11+ / Docker Compose API v2+

## Contents
- [Installation](#installation)
- [Commands](#commands)
    - [New](#new)
        - [Try it](#try-the-new-command)
    - [Templates](#templates)
        - [Try it](#try-the-templates-command)
- [Available templates](#available-templates)
    - [Base](#base)
- [FAQ](#faq)
    - [How can I learn about the Docker specific aspects of the project?](#how-can-i-learn-about-the-docker-specific-aspects-of-the-project)
    - [What do I do after I generate the application?](#what-do-i-do-after-i-generate-the-application)
    - [What's the bare minimum to get things running?](#whats-the-bare-minimum-to-get-things-running)
    - [Do I need to install orats to use the base app?](#do-i-need-to-install-orats-to-use-the-base-app)

## Installation

`gem install orats`

Or if you already have orats then run `gem update orats` to upgrade to the
latest version.

If you don't have Ruby installed, then you can
[generate an app easily with bash](#do-i-need-to-install-orats-to-use-the-base-app).

## Commands

To get the details of each command then please run `orats help` from the
terminal. Here's a high level overview:

### New

The new command generates a new orats app, which is just a Rails app in the end.

Currently there is only 1 template, which is the "base" template but others may
be added in the future.

#### Try the new command

`orats new myproject`

### Templates

Return a list of available templates to choose from.

#### Try the templates command

`orats templates`

## Available templates

### Base

This is the starter template that every other template will be based upon. I
feel like when I make a new project, 95% of the time it includes these features
and when I do not want a specific thing it is much quicker to remove it than
add it.

#### Main changes vs a fresh Rails project

- **Core changes**:
    - Use `postgres` as the primary SQL database
    - Use `redis` as the cache backend
    - Use `sidekiq` as a background worker through Active Job
    - Use a standalone Action Cable server
    - jQuery is installed with `jquery-rails`
    - Capybara is commented out in the `Gemfile`
- **Features**:
    - Add a `pages` controller with `home` action
- **Config**:
    - Extract a bunch of configuration settings to environment variables
    - Rewrite the `database.yml` and `secrets.yml` files
    - Add a staging environment
    - **Development mode only**:
        - Use `rack mini profiler` for profiling / analysis
    - **Production mode only**:
        - Add popular file types to the assets pre-compile list
    - Log to STDOUT so that Docker can consume and deal with log entries
    - Change validation errors to output in-line on each element instead of a big list
- **Helpers**:
    - `title`, `meta_description`, `heading` to easily set those values per view
    - `humanize_boolean` to convert true / false into Yes / No
    - `css_for_boolean` to convert true / false into a css class success / danger
- **Views**:
    - Use `scss` and `javascript`
    - Use `bootstrap 3.x` and `font-awesome 4.x`
    - Add a minimal and modern layout file
    - Conditionally load `html5shiv`, `json3` and `respondjs` for IE < 9 support
    - **Partials**:
        - Add navigation
        - Add flash message
        - Add footer
        - Add Google Analytics

## FAQ

#### How can I learn about the Docker specific aspects of the project?

Check out the blog post
[Dockerize a Rails 5, Postgres, Redis, Sidekiq and Action Cable Application](http://nickjanetakis.com/blog/dockerize-a-rails-5-postgres-redis-sidekiq-action-cable-app-with-docker-compose).

Another option is to take my [Dive Into Docker course](https://diveintodocker.com/courses/dive-into-docker?utm_source=orats&utm_medium=github&utm_campaign=readmebottom).

#### What do I do after I generate the application?

Start by reading the above blog post, because the Docker blog post explains
how you can run the project. It also goes over a few Docker related caveats
that may hang you up if you're not already familiar with Docker.

After that, just dive into the project's source code and write your awesome app!

#### What's the bare minimum to get things running?

If you don't feel like reading the blog post, this is the bare minimum to get
everything up and running -- assuming you have Docker and Docker Compose installed.

```sh
# 1) Read the .env file carefully and change any user specific settings, such
#    as e-mail credentials and platform specific settings (check the comments).
#
# 2) Build and run the project with Docker Compose
docker-compose up --build
#
# 3) Reset and Migrate the database (run this in a 2nd Docker-enabled terminal)
# OSX / Windows users can skip adding the --user "$(id -u):$(id -g)" flag
docker-compose exec --user "$(id -u):$(id -g)" website rails db:reset
docker-compose exec --user "$(id -u):$(id -g)" website rails db:migrate
#
# 4a) Running Docker natively? Visit http://localhost:3000
# 4b) Running Docker with the Toolbox? Visit http://192.168.99.100:3000
#     (you may need to replace 192.168.99.100 with your Docker machine IP)
```

#### Do I need to install orats to use the base app?

Not really. The base application is already generated and you can view it
[directly in this repo](https://github.com/nickjj/orats/tree/master/lib/orats/templates/base).

The main benefit of the orats gem is that it will do a recursive find / replace
on a few strings to personalize the project for your project's name. It will
also make it easy to pick different templates when they are available.

You could easily do this yourself if you don't have Ruby installed on your work
station. The 3 strings you'll want to replace are:

- `OratsBase` (used as class names and in the generated home page)
- `orats_base` (used for a number of Rails specific prefixes and more)
- `VERSION` (used to set the current orats version in the generated home page)

You could whip up a simple bash script to do this, such as:

```sh
# Clone this repo to a directory of your choosing.
git clone https://github.com/nickjj/orats /tmp/orats

# Copy the base project to a directory of your choosing.
cp -r /tmp/orats/lib/orats/templates/base /tmp/foo_bar

# Swap a few custom values into the base project.
find /tmp/foo_bar -type f -exec sed -i -e 's/OratsBase/FooBar/g' {} \;
find /tmp/foo_bar -type f -exec sed -i -e 's/orats_base/foo_bar/g' {} \;
find /tmp/foo_bar -type f -exec sed -i -e 's/VERSION/5.1.1/g' {} \;

# Rename the example .env file since `.env` is git ignored.
mv /tmp/orats/.env.example /tmp/orats/.env

# Clean up the cloned directory.
rm -rf /tmp/orats
```
