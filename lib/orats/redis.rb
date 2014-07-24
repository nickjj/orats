module Orats
  # manage the redis process
  module Redis
    def redis_bin(bin_name = 'redis-cli')
      exec = "#{bin_name} -h #{@options[:redis_location]}"

      return exec if @options[:redis_password].empty?
      exec << " -a #{@options[:redis_password]}"
    end

    def drop_namespace(namespace)
      run "#{redis_bin} KEYS '#{namespace}:*'| " + \
          "xargs --delim='\n' #{redis_bin} DEL"
    end

    def exit_if_redis_unreachable
      task 'Check if you can ping redis'

      return if run("#{redis_bin} ping")

      error 'Cannot ping redis', 'attempt to PING'
      exit 1
    end
  end
end
