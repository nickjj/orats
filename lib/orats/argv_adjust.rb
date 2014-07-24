require 'orats/ui'

module Orats
  # adjust ARGV by adding args from the .oratsrc file if necessary
  class ARGVAdjust
    include Orats::UI

    def initialize(argv = ARGV)
      @argv = argv

      @default_rc_file = File.expand_path('~/.oratsrc')
      @rc_path = ''
    end

    def init
      rc_path @argv.first
      return @argv if @rc_path.empty?

      argv
    end

    private

    def rc_path(command)
      return unless command == 'new' || command == 'nuke'

      rc_flag = @argv.index { |item| item.include?('--rc') }

      if rc_flag
        cli_rc_file(rc_flag)
      elsif File.exist?(@default_rc_file)
        @rc_path = @default_rc_file
      end
    end

    def argv
      if File.exist?(@rc_path)
        extra_args = File.readlines(@rc_path).flat_map(&:split)
        results 'Using values from an .oratsrc file',
                'args', extra_args.join(' ')
        puts

        (@argv += extra_args).flatten
      else
        error 'The .oratsrc file cannot be found', @rc_path
      end
    end

    def cli_rc_file(index)
      rc_value = @argv[index]

      if rc_value.include?('=')
        @rc_path = rc_value.gsub('--rc=', '')
        @argv.slice! index
      elsif rc_value == '--rc'
        @rc_path = @argv[index + 1]
        @argv.slice! index + 1
      end
    end
  end
end
