require 'open-uri'
require 'orats/ui'

module Orats
  class Outdated
    include UI

    RELATIVE_PATHS = {
        galaxyfile: 'templates/includes/Galaxyfile',
        inventory: 'templates/includes/inventory/group_vars/all.yml',
        playbook: 'templates/play.rb',
        version: 'version.rb'
    }

    REMOTE_FILE_PATHS = {} ; LOCAL_FILE_PATHS = {}

    def initialize(options = {})
      @options = options

      @remote_gem_version = parse_gem_version

      build_common_paths
      @remote_galaxyfile = parse_galaxyfile url_to_string(REMOTE_FILE_PATHS[:galaxyfile])
      @remote_inventory = parse_inventory url_to_string(REMOTE_FILE_PATHS[:inventory])
      @remote_playbook = parse_playbook url_to_string(REMOTE_FILE_PATHS[:playbook])

      @local_galaxyfile = parse_galaxyfile file_to_string(LOCAL_FILE_PATHS[:galaxyfile])
      @local_inventory = parse_inventory file_to_string(LOCAL_FILE_PATHS[:inventory])
      @local_playbook = parse_playbook file_to_string(LOCAL_FILE_PATHS[:playbook])
    end

    def exec
      compare_remote_to_local_gem_versions
      compare_remote_to_local_galaxyfiles
      compare_remote_to_local 'inventory', 'variables', @remote_inventory, @local_inventory
      compare_remote_to_local 'playbook', 'roles', @remote_playbook, @local_playbook

      unless @options[:playbook].empty?
        compare_local_to_user('playbook', 'roles', @options[:playbook], @local_playbook) do
          parse_playbook file_to_string(@options[:playbook])
        end
      end

      unless @options[:inventory].empty?
        compare_local_to_user('inventory', 'variables', @options[:inventory], @local_inventory) do
          parse_inventory file_to_string(@options[:inventory])
        end
      end
    end

    private

    def base_path
      File.expand_path File.dirname(__FILE__)
    end

    def repo_path
      %w(https://raw.githubusercontent.com/nickjj/orats lib/orats)
    end

    def build_common_paths
      files = [:galaxyfile, :inventory, :playbook]

      files.each do |file|
        LOCAL_FILE_PATHS[file] = "#{base_path}/#{RELATIVE_PATHS[file]}"
        REMOTE_FILE_PATHS[file] = "#{repo_path[0]}/#{@remote_gem_version}/#{repo_path[1]}/#{RELATIVE_PATHS[file]}"
      end
    end

    def url_to_string(url)
      begin
        url_contents = open(url).read
      rescue *[OpenURI::HTTPError, SocketError] => ex
        log_error 'error', "Error accessing URL #{url}",
                  'message', ex
        exit 1
      end

      url_contents
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

    def parse_gem_version
      REMOTE_FILE_PATHS[:version] = "#{repo_path[0]}/master/#{repo_path[1]}/#{RELATIVE_PATHS[:version]}"
      "v#{url_to_string(REMOTE_FILE_PATHS[:version]).match(/'(.*)'/)[1..-1].first}"
    end

    def parse_galaxyfile(contents)
      contents.split
    end

    def parse_inventory(contents)
      # pluck out all of the values contained with {{ }}
      ansible_variables = contents.scan(/\{\{([^{{}}]*)\}\}/)

      # remove the leading space
      ansible_variables.map! { |line| line.first[0] = '' }

      # match every line that is not a comment and contains a colon
      inventory_variables = contents.scan(/^[^#].*:/)

      inventory_variables.map! do |line|
        # only strip lines that need it
        line.strip! if line.include?(' ') || line.include?("\n")

        # get rid of the trailing colon
        line.chomp(':')

        # if a value of a certain variable has a colon then the regex
        # picks this up as a match. only take the variable name
        # if this happens to occur
        line.split(':').first if line.include?(':')
      end

      (ansible_variables + inventory_variables).uniq.delete_if(&:empty?)
    end

    def parse_playbook(contents)
      # match every line that is not a comment and has a role defined
      roles = contents.scan(/^.*role:.*/)

      roles.map! do |line|
        line.strip! if line.include?(' ') || line.include?("\n")

        role_parts = line.split('role:')

        # start at the actual role name
        line = role_parts[1]

        if line.include?(',')
          line = line.split(',').first
        end

        line.strip! if line.include?(' ')
      end

      roles.uniq
    end

    def compare_remote_to_local_gem_versions
      log_remote_info 'gem', 'Comparing this version of orats to the latest orats version',
                      'version', "Latest: #{@remote_gem_version}, Yours: v#{VERSION}"
    end

    def compare_remote_to_local_galaxyfiles
      galaxyfile_diff = @remote_galaxyfile - @local_galaxyfile
      local_galaxyfile_as_string = @local_galaxyfile.join
      local_galaxyfile_roles = @local_galaxyfile.size
      roles_diff_count = galaxyfile_diff.size

      log_status_top 'roles', "Comparing this version of orats' roles to the latest version:", :green

      if roles_diff_count == 0
        log_status_bottom 'message', "All #{local_galaxyfile_roles} roles are up to date", :yellow
      else
        log_status_bottom 'message', "There are #{roles_diff_count} differences", :yellow

        galaxyfile_diff.each do |line|
          name = line.split(',').first
          status = 'outdated'
          color = :yellow

          unless local_galaxyfile_as_string.include?(name)
            status = 'missing'
            color = :red
          end

          log_status_bottom status, name, color, true
        end

        log_results 'The latest version of orats may benefit you', 'Check github to see if the changes interest you'
      end
    end

    def compare_remote_to_local(label, keyword, remote, local)
      item_diff = remote - local
      item_diff_count = item_diff.size

      log_remote_info label, "Comparing this version of orats' #{label} to the latest version",
                      'file', label == 'playbook' ? 'site.yml' : 'all.yml'

      item_diff.each do |line|
        log_status_bottom 'missing', line, :red unless local.include?(line)
      end

      if item_diff_count > 0
        log_results "#{item_diff_count} new #{keyword} are available", 'You may benefit from upgrading to the latest orats'
      else
        log_results 'Everything appears to be in order', "No missing #{keyword} were found"
      end
    end

    def compare_local_to_user(label, keyword, flag_path, local)
      user = yield

      log_local_info label, "Comparing this version of orats' #{label} to #{File.basename(flag_path)}",
                     'path', flag_path

      missing_count = log_unmatched(local, user, 'missing', :red)
      extra_count = log_unmatched(user, local, 'extra', :yellow)

      if missing_count > 0
        log_results "#{missing_count} #{keyword} are missing", "Your ansible run will likely fail with this #{label}"
      else
        log_results 'Everything appears to be in order', "No missing #{keyword} were found"
      end

      if extra_count > 0
        log_results "#{extra_count} extra #{keyword} were detected:", "No problem but remember to add them to future #{keyword}"
      else
        log_results "No extra #{keyword} were found:", "Extra #{keyword} are fine but you have none"
      end
    end

    def log_unmatched(compare, against, label, color)
      count = 0

      compare.each do |item|
        unless against.include?(item)
          log_status_bottom label, item, color, true
          count += 1
        end
      end

      count
    end
  end
end