require 'orats/commands/common'
require 'orats/commands/project/rails'

module Orats
  module Commands
    class Playbook < Common
      include Project::Rails

      def initialize(target_path = '', options = {})
        super
      end

      def init
        exit_if_path_exists

        rails_template 'playbook'
        custom_rails_template unless @options[:custom].empty?
      end
    end
  end
end