Rack::Timeout.timeout = ENV.fetch('REQUEST_TIMEOUT') { 5 }.to_i
