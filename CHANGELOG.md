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
