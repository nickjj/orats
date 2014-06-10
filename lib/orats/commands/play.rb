require 'orats/commands/common'
require 'orats/commands/new/rails'

module Orats
  module Commands
    class Play < Common
      include New::Rails

      def initialize(target_path = '', options = {})
        super
      end

      def init
        exit_if_path_exists

        rails_template 'play'
        custom_rails_template unless @options[:template].empty?
      end
    end
  end
end