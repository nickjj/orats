## orats 5.2.3 (September 29, 2018)

- Fix Rack timeout error by introducing `RACK_TIMEOUT_SERVICE_TIMEOUT` in `.env`

## orats 5.2.2 (April 19, 2018)

- Fix undefined `_r` variable / method error in `content_security_policy.rb`

## orats 5.2.1 (April 12, 2018)

- Fix hardcoded `POSTGRES_USER` value

## orats 5.2.0 (April 11, 2018)

- Update PostgreSQL to `10.3`
- Update Redis to `4.0`
- Update Ruby to `2.5.x`
- Update Rails to `5.2.0`
- Update puma to `3.11`
- Update pg to `1.0`
- Update sidekiq to `5.1`
- Update rack-mini-profiler to `1.0`
- Unpublish PostgreSQL port in `docker-compose.yml`
- Unpublish Redis port in `docker-compose.yml`
- Move PostgreSQL environment variables to the `.env` file
- Drastically reduce log spam in the test output
- Bootsnap is disabled for now (it may be enabled in a later release)
- Credentials are not being used for the time being

## orats 5.1.2 (August 23, 2017)

- Fix missing `fileutil` require
- Update Rails to `5.1.3`
- Update Puma to `3.10`

## orats 5.1.1 (June 16, 2017)

- Update Ruby to `2.4`
- Update rails to `5.1.1`
- Update sidekiq to `5.0`
- Update Puma to `3.9`
- Update pg to `0.21`
- Update redis-rails to `5.0`
- Bring back jQuery with `jquery-rails`
- Comment out Capybara in the `Gemfile` (Rails 5.1 has it enabled by default)
- Switch from Debian to Alpine as a base image in the `Dockerfile`
- Remove compiling assets inside of the `Dockerfile`
- Hard code `/app` in the `Dockerfile` and `docker-compose.yml` volumes
- Change the `MAINTAINER` instruction to use a `LABEL` in the `Dockerfile`

## orats 5.0.3 (December 21, 2016)

- Update Rails to `5.0.1`
- Update Sidekiq to `4.2.x`
- Update Font Awesome to `4.7.x`

## orats 5.0.2 (July 11, 2016)

- Fix `Dockerfile` to use orats_base not my_dockerized_app

## orats 5.0.1 (July 10, 2016)

- Fix missing `.env` file (Fixes #12)

## orats 5.0.0 (July 8, 2016)

- Update everything for Rails 5.0
- Use Docker for building and running the project
- Drastically simplify the internals
