[![Gem Version](https://badge.fury.io/rb/orats.png)](http://badge.fury.io/rb/orats)

## What is orats and what problem does it solve?

It stands for opinionated rails application templates. The templates include solving tedious tasks that you would do for most projects. It handles creating a rails application with a bunch of opinions and best practices.

## What version of Rails and Ruby are you targeting?

#### Rails 4.1.x and Ruby 2.1.x

Gems will also be updated once they are proven to work on the target rails/ruby versions. The gems are locked using the pessimistic operator `~>` to ensure your installation works over time as long as rubygems.org's API is working.

## Contents
- [System dependencies](#system-dependencies)
- [Installation](#installation)
- [Commands](#commands)
    - [New](#new)
        - [Try it](#try-the-new-command)
    - [Nuke](#nuke)
        - [Try it](#try-the-nuke-command)
    - [Templates](#templates)
        - [Try it](#try-the-templates-command)
- [Available templates](#available-templates)
    - [Base](#base)
        - [Try it](#try-the-base-template)
    - [Auth](#auth)
        - [Try it](#try-the-auth-template)
    - [Custom](#custom)
        - [Try it](#try-the-custom-template)
        - [FAQ](#custom-faq)
            - [Any guides on how to make custom templates?](#any-guides-on-how-to-make-custom-templates)
- [The .oratsrc file](#the-oratsrc-file)
- [Wiki](https://github.com/nickjj/orats/wiki)
    - [What to look at after making a new project](https://github.com/nickjj/orats/wiki/What-to-look-at-after-making-a-new-project)

## System dependencies

Before running orats...

#### You must install

- [Git](http://git-scm.com/book/en/Getting-Started-Installing-Git)
- [Postgres](https://wiki.postgresql.org/wiki/Detailed_installation_guides)
- [Redis](http://redis.io/topics/quickstart)
- Ruby 2.1.x - [chruby](https://github.com/postmodern/chruby) | [rbenv](https://github.com/sstephenson/rbenv) | [rvm](https://rvm.io/)
- Rails 4.1.x - `gem install rails -v '~> 4.1.4'`

#### You should install

- [Imagemagick](https://www.google.com/search?q=install+imagemagick)
    - If you want favicons to be automatically created (optional)

#### You need these processes to be running

- Postgres
- Redis

## Installation

`gem install orats`

Or if you already have orats then run `gem update orats` to upgrade to the latest version.

## Commands

To get the details of each command then please run `orats help` from the terminal. Below is a high level overview of what the main commands do.

### New

The new command kicks off a new orats app. It will always use the base template and optionally allows you to provide the `--template foo` flag where `foo` would be an available template provided by orats.

You can also supply your own custom template which is explained in the [custom template](#custom) section.

Get started by checking out what the [base template](#base) provides.

### Nuke

You can delete an app using the nuke command. It is much better than just using `rm -rf` because it will clean up the postgres and redis namespace as long as you don't disable that functionality with the `--skip-data` flag.

#### Try the nuke command

You will need to have generated an app before trying this. Check out the [try the base template](#try-the-base-template) section to learn how to generate an app.

`orats nuke /tmp/someapp --pg-password foo`

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
    - Use `unicorn` or `puma` as the web backend
    - Use `sidekiq` as a background worker
- **Features**:
    - Configure scheduled jobs and tasks using `whenever`
    - Pagination and a route concern mapped to `/page` using `kaminari`
    - Keep a sitemap up to date using `sitemap_generator`
    - Add a `pages` controller with `home` action that has points of interest
- **Rake tasks**:
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
    - Add a deploy page that could be swapped in/out during server deploys
    - Add all of the favicons output by the favicon generator

#### Try the base template

`orats new myapp --pg-password foo`

#### Base FAQ

##### What is `--pg-password`?

Orats will automatically start your server (you can turn this off with a flag) and also run database migrations or generators depending on what you're doing.

In order to do this it must know your postgres location, username and password. By default it will use localhost for the *location* and *postgres* as the username but if you need to supply those values because yours are different you can use `--pg-location foo` and `--pg-username bar`.

##### Does your redis server use a password?

If your redis server is configured to use a password then you must also pass in `--redis-password foo`.

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

`orats new myauthapp --template auth --pg-password foo`

### Custom

You can pass custom templates into the `new` command. It works exactly like passing a custom application template to `rails new`.

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

`orats new /tmp/customexample -p foo --custom /tmp/foo.rb`

#### Custom FAQ

<a name="any-guides-on-how-to-make-custom-templates"></a>
##### Any guides on how to make custom templates?

There's the official [rails guide on custom application templates]
(http://guides.rubyonrails.org/rails_application_templates.html).

You can also view the [orats templates](https://github.com/nickjj/orats/tree/master/lib/orats/templates) to use as inspiration. All of the template files are self contained.

## The .oratsrc file

Both the `new` and `nuke` commands are dependent on having your postgres and redis login information because they need to connection to those databases to perform various tasks.

There are 7 flags to configure for this:

- `--pg-location` (defaults to localhost)
- `--pg-port` (defaults to 5432)
- `--pg-username` (defaults to postgres)
- `--pg-password` (defaults to an empty string)
- `--redis-location` (defaults to localhost)
- `--redis-port` (defaults to 6379)
- `--redis-password` (defaults to an empty string)

For most people you will only need to supply the postgres password but still it's annoying to have to type those flags in every time you create a new app or nuke an app. It's really annoying if you develop inside of linux containers like myself which means the location is not localhost.

This is where the `.oratsrc` file comes into play. By default it will look for one in your home directory but you can pass in a location directly with the `--rc` flag.

This file can contain the above flags. You might have one created at `~/.oratsrc`
 and it could look like this:

```
--pg-location 192.168.144.101
--pg-username nick
--pg-password pleasedonthackme
--redis-location 192.168.144.101
```

You can supply as many or little flags as you want.
