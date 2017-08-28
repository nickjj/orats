require 'fileutils'
require 'pathname'

require 'orats/common'
require 'orats/util'
require 'orats/version'

module Orats
  module Commands
    class New < Common
      AVAILABLE_TEMPLATES = {
        base: 'dockerized production ready application',
        slim: 'dockerized production ready application with slim templates'
      }.freeze

      def initialize(target_path = '', options = {})
        super
      end

      def init
        check_exit_conditions
        create_template
        personalize_template
        rename_env_file
        what_to_do_next
      end

      def available_templates
        puts
        log 'templates',
            'Add `-t TEMPLATE` to the new command to use a template',
            :magenta
        puts

        AVAILABLE_TEMPLATES.each_pair do |key, value|
          log key, value, :cyan
        end
      end

      private

      def check_exit_conditions
        exit_if_path_exists
        exit_if_invalid_template
      end

      def exit_if_invalid_template
        template = @options[:template] || ''
        task 'Check if template exists'

        return if template.empty? || template_exist?

        error 'Cannot find template',
              "'#{template}' is not a valid template name"

        available_templates
        exit 1
      end

      def template_exist?
        AVAILABLE_TEMPLATES.include?(@options[:template].to_sym)
      end

      def create_template
        task "Create '#{@options[:template]}' project"
        log 'path', @target_path, :cyan

        source = "#{base_path}/templates/#{@options[:template]}"

        FileUtils.copy_entry source, @target_path
      end

      def personalize_template
        template_replacements = set_template_replacements

        Dir.glob("#{@target_path}/**/*", File::FNM_DOTMATCH) do |file|
          next if file == '.' || file == '..' || File.directory?(file)

          text = File.read(file)

          template_replacements.each do |key, value|
            text.gsub!(key.to_s, value)
          end

          File.open(file, 'w') { |f| f.puts text }
        end
      end

      def rename_env_file
        env_file_source = File.join(@target_path, '.env.example')
        env_file_destination = File.join(@target_path, '.env')

        File.rename(env_file_source, env_file_destination)
      end

      def set_template_replacements
        project_name = Pathname.new(@target_path).basename.to_s

        {
          'orats_base' => Util.underscore(project_name),
          'OratsBase'  => Util.classify(project_name),
          'VERSION'    => VERSION
        }
      end

      def what_to_do_next
        prepare_and_run_everything
        init_the_database
        visit_the_page
      end

      def prepare_and_run_everything
        task 'Prepare and run everything'
        log 'open', 'carefully read and edit the `.env` file', :cyan
        log 'move', "cd #{@target_path}", :cyan
        log 'run', 'docker-compose up --build', :cyan
      end

      def init_the_database
        run = 'docker-compose exec --user "$(id -u):$(id -g)" website rails'

        task 'Initialize the database in a 2nd Docker-enabled terminal'
        log 'note', 'OSX / Windows users can skip the --user flag', :yellow
        log 'run', "#{run} db:reset", :cyan
        log 'run', "#{run} db:migrate", :cyan
      end

      def visit_the_page
        task 'Visit the page in your browser'
        log 'visit', 'Running Docker natively? http://localhost:3000', :cyan
        log 'visit',
            'Running Docker with the Toolbox? http://192.168.99.100:3000',
            :cyan
      end
    end
  end
end
