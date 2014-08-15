web: unicorn -c config/unicorn.rb | grep -v --line-buffered ' 304 -'
worker: sidekiq -C config/sidekiq.yml
log: tail -f $LOG_FILE | grep -xv --line-buffered '^[[:space:]]*' | grep -v --line-buffered '/assets/' | grep -v --line-buffered 'HTTP/1.1' 
