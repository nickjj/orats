web: puma -C config/puma.rb | grep -v --line-buffered ' 304 -'
worker: sidekiq -C config/sidekiq.yml
log: tail -f log/development.log | grep -xv --line-buffered '^[[:space:]]*' | grep -v --line-buffered '/assets/'
