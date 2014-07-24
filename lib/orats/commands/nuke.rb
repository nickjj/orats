require 'orats/common'

module Orats
  module Commands
    # delete a path and its data
    class Nuke < Common
      def initialize(target_path = '', options = {})
        super
      end

      def init
        exit_if_invalid_system

        nuke_report
        nuke_details
        nuke_data unless @options[:skip_data]
        nuke_path
      end

      private

      def exit_if_path_missing
        task 'Check if path is missing'

        return if Dir.exist?(@target_path) || File.exist?(@target_path)

        error 'Path was not found', @target_path
        exit 1
      end

      def nuke_report
        puts
        log 'warning', 'You are about to permanently delete this path',
            :yellow, true
        log 'nuke path', File.expand_path(@target_path), :white
        puts
      end

      def nuke_details
        rails_apps = []

        valid_rails_apps.each do
          |rails_dir| rails_apps << File.basename(rails_dir)
        end

        nuke_items(rails_apps) unless @options[:skip_data]
      end

      def valid_rails_apps
        rails_gemfiles =
            run("find #{@target_path} -type f -name Gemfile | " + \
                "xargs grep -lE \"gem 'rails'|gem \\\"rails\\\"\"",
                capture: true)

        gemfile_paths = rails_gemfiles.split("\n")

        gemfile_paths.map { |gemfile| File.dirname(gemfile) }
      end

      def nuke_items(apps)
        if apps.empty?
          results 'No apps were found in this path',
                  'skipping', File.expand_path(@target_path)
          nuke_path
          exit
        else
          nuke_app_details(apps.join(', '))
        end
      end

      def nuke_app_details(app_names)
        puts
        log 'nuke', 'You are about to permanently delete all postgres' + \
            ' databases for', :red, true
        log 'databases', app_names, :yellow
        puts
        log 'nuke', 'You are about to permanently delete all redis' + \
            ' namespaces for', :red, true
        log 'namespaces', app_names, :yellow
        puts

        exit unless yes?('Are you sure? (y/N)', :cyan)
      end

      def nuke_data
        valid_rails_apps.each do |app|
          task 'Delete postgres database'
          drop_database app

          task 'Delete redis keys'
          drop_namespace File.basename(app)
        end
      end

      def nuke_path
        exit_if_path_missing

        task 'Delete path'

        return if @options[:skip_data]

        puts
        exit unless yes?('Are you sure? (y/N)', :cyan)
        run "rm -rf #{@target_path}"
      end
    end
  end
end
