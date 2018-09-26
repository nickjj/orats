require 'orats/ui'

module Orats
  # common class that other CLI driven classes subclass
  class Common
    include Thor::Base
    include Thor::Shell
    include Thor::Actions
    include UI

    def initialize(target_path = '', options = {})
      @target_path = target_path
      @options     = options

      self.destination_root = Dir.pwd
      @behavior             = :invoke
    end

    def base_path
      __dir__
    end

    def file_to_string(path)
      if File.exist?(path) && File.file?(path)
        IO.read path
      else
        error 'Path not found', path
        exit 1
      end
    end

    def exit_if_path_exists(extend_path = '')
      task 'Check if path exists'

      extended_path = @target_path.dup

      unless extend_path.empty?
        extended_path = File.join(extended_path, extend_path)
      end

      return unless Dir.exist?(extended_path) || File.exist?(extended_path)

      error 'Path already exists', extended_path
      exit 1
    end
  end
end
