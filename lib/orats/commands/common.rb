require 'orats/commands/ui'
require 'orats/commands/diff/parse'

module Orats
  module Commands
    class Common
      include Thor::Base
      include Thor::Shell
      include Thor::Actions
      include UI
      include Diff::Parse

      RELATIVE_PATHS = {
          galaxyfile: 'templates/includes/play/Galaxyfile',
          hosts:      'templates/includes/new/ansible/inventory/hosts.ini',
          inventory:  'templates/includes/new/ansible/inventory/group_vars/all.yml',
          playbook:   'templates/includes/play/site.yml',
          version:    'version.rb'
      }

      attr_accessor :remote_gem_version, :remote_paths, :local_paths

      def initialize(target_path = '', options = {})
        @target_path = target_path
        @options     = options
        @active_path = @target_path

        @local_paths  = {}
        @remote_paths = {}

        build_common_paths

        self.destination_root = Dir.pwd
        @behavior             = :invoke
      end

      def self.copy_from_local_gem(source, dest)
        base_path           = File.join(File.expand_path(File.dirname(__FILE__)),
                                      '..')
        template_path       = "#{base_path}/templates/includes"

        system "mkdir -p #{File.dirname(dest)}" unless Dir.exist?(File.dirname(dest))
        system "cp #{template_path}/#{source} #{dest}"
      end

      def base_path
        File.join(File.expand_path(File.dirname(__FILE__)), '..')
      end

      def repo_path
        %w(https://raw.githubusercontent.com/nickjj/orats lib/orats)
      end

      def url_to_string(url)
        begin
          open(url).read
        rescue *[OpenURI::HTTPError, SocketError] => ex
          log_error 'error', "Error accessing URL #{url}",
                    'message', ex
          exit 1
        end
      end

      def file_to_string(path)
        if File.exist?(path) && File.file?(path)
          IO.read(path)
        else
          log_error 'error', 'Error finding file',
                    'message', path
          exit 1
        end
      end

      def exit_if_path_exists
        log_task 'Check if this path exists'

        if Dir.exist?(@active_path) || File.exist?(@active_path)
          log_error 'error', 'A file or directory already exists at this location', 'path', @active_path
          exit 1
        end
      end

      def exit_if_process(check_for, *processes)
        case check_for
          when :not_found
            command = 'which'
            phrase  = 'on your system path'
          when :not_running
            command = 'ps cax | grep'
            phrase  = 'running'
          else
            command = ''
            phrase  = ''
        end

        processes.each do |process|
          log_task "Check if #{process} is #{phrase}"

          exit 1 if process_unusable?("#{command} #{process}", process, phrase)
        end
      end

      private

      def build_common_paths
        @remote_paths[:version] = select_branch 'master', RELATIVE_PATHS[:version]
        @remote_gem_version     = gem_version

        RELATIVE_PATHS.each_pair do |key, value|
          @local_paths[key]  = "#{base_path}/#{value}"
          @remote_paths[key] = select_branch @remote_gem_version,
                                             check_old_remote_file_paths(value)
        end
      end

      def check_old_remote_file_paths(url)
        if VERSION < '0.6.6'
          url.gsub!('play/', '')
          url.gsub!('new/ansible/', '')
          url.gsub!('includes/site.yml', 'play.rb')
        end

        url
      end

      def select_branch(branch, value)
        "#{repo_path[0]}/#{branch}/#{repo_path[1]}/#{value}"
      end

      def process_unusable?(command, process, phrase)
        command_output = run(command, capture: true)

        log_error 'error', "Cannot detect #{process}", 'question', "Are you sure #{process} is #{phrase}?", true do
          log_status_bottom 'tip', "#{process} must be #{phrase} before running this orats command", :white
        end if command_output.empty?

        command_output.empty?
      end
    end
  end
end
