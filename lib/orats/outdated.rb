module Orats
  module Outdated
    def outdated_init
      latest_gem_version = compare_gem_version

      github_repo = "https://raw.githubusercontent.com/nickjj/orats/#{latest_gem_version}/lib/orats"

      galaxy_url = "#{github_repo}/templates/includes/Galaxyfile"
      playbook_url = "#{github_repo}/templates/play.rb"
      inventory_url = "#{github_repo}/templates/includes/inventory/group_vars/all.yml"

      remote_galaxy_contents = url_to_string(galaxy_url)
      remote_playbook_contents = url_to_string(playbook_url)
      remote_inventory_contents = url_to_string(inventory_url)

      compare_remote_role_version_to_local remote_galaxy_contents

      local_playbook = compare_remote_to_local('playbook',
                                               'roles',
                                               playbook_file_stats(remote_playbook_contents),
                                               playbook_file_stats(IO.read(playbook_file_path)))

      local_inventory = compare_remote_to_local('inventory',
                                                'variables',
                                                inventory_file_stats(remote_inventory_contents),
                                                inventory_file_stats(IO.read(inventory_file_path)))

      unless @options[:playbook].empty?
        compare_user_to_local('playbook', 'roles', @options[:playbook], local_playbook) do
          playbook_file_stats IO.read(@options[:playbook])
        end
      end

      unless @options[:inventory].empty?
        compare_user_to_local('inventory', 'variables', @options[:inventory], local_inventory) do
          inventory_file_stats IO.read(@options[:inventory])
        end
      end
    end

    private

    def inventory_file_stats(file)
      # pluck out all of the values contained with {{ }}
      ansible_variable_list = file.scan(/\{\{([^{{}}]*)\}\}/)

      # remove the leading space
      ansible_variable_list.map! { |line| line.first[0] = '' }

      # match every line that is not a comment and contains a colon
      inventory_variable_list = file.scan(/^[^#].*:/)

      inventory_variable_list.map! do |line|
        # only strip lines that need it
        line.strip! if line.include?(' ') || line.include?("\n")

        # get rid of the trailing colon
        line.chomp(':')

        # if a value of a certain variable has a colon then the regex
        # picks this up as a match. only take the variable name
        # if this happens to occur
        line.split(':').first if line.include?(':')
      end

      (ansible_variable_list + inventory_variable_list).uniq
    end

    def playbook_file_stats(file)
      # match every line that is not a comment and has a role defined
      roles_list = file.scan(/^.*role:.*/)

      roles_list.map! do |line|
        # only strip lines that need it
        line.strip! if line.include?(' ') || line.include?("\n")

        role_parts = line.split('role:')

        line = role_parts[1]

        if line.include?(',')
          line = line.split(',').first
        end

        line.strip! if line.include?(' ')
      end

      roles_list.reject! { |line| line.start_with?('#') }

      roles_list.uniq
    end

    def compare_gem_version
      latest_gem_contents = `gem list orats --remote`.split.last

      if latest_gem_contents.include?('ERROR')
        log_error 'error', 'Error running `gem list orats --remote`',
                  'message', 'Chances are their API is down, try again soon'
        exit 1
      end

      latest_gem_version = "v#{latest_gem_contents.split.first[1...-1]}"

      log_remote_info 'gem', 'Comparing this version of orats to the latest orats version',
                      'version', "Latest: #{latest_gem_version}, Yours: v#{VERSION}"

      latest_gem_version
    end

    def compare_remote_role_version_to_local(remote_galaxy_contents)
      remote_galaxy_list = remote_galaxy_contents.split
      local_galaxy_contents = IO.read(galaxy_file_path)
      local_galaxy_list = local_galaxy_contents.split

      galaxy_difference = remote_galaxy_list - local_galaxy_list

      local_role_count = local_galaxy_list.size
      different_roles = galaxy_difference.size

      log_status_top 'roles', "Comparing this version of orats' roles to the latest version:", :green

      if different_roles == 0
        log_status_bottom 'message', "All #{local_role_count} roles are up to date", :yellow
      else
        log_status_bottom 'message', "There are #{different_roles} differences", :yellow

        galaxy_difference.each do |role_line|
          name = role_line.split(',').first
          status = 'outdated'
          color = :yellow

          unless local_galaxy_contents.include?(name)
            status = 'missing'
            color = :red
          end

          log_status_bottom status, name, color
        end

        log_results 'The latest version of orats may benefit you', 'Check github to see if the changes interest you'
      end
    end

    def compare_remote_to_local(label, keyword, remote_list, local_list)
      list_difference = remote_list - local_list

      remote_count = list_difference.size

      log_remote_info label, "Comparing this version of orats' #{label} to the latest version",
                      'file', label == 'playbook' ? 'site.yml' : 'all.yml'

      list_difference.each do |line|
        log_status_bottom 'missing', line, :red unless local_list.include?(line)
      end

      if remote_count > 0
        log_results "#{remote_count} new #{keyword} are available", 'You may benefit from upgrading to the latest orats'
      else
        log_results 'Everything appears to be in order', "No missing #{keyword} were found"
      end

      local_list
    end

    def compare_user_to_local(label, keyword, user_path, local_list)
      if File.exist?(user_path) && File.file?(user_path)
        user_list = yield

        just_file_name = user_path.split('/').last

        log_local_info label, "Comparing this version of orats' #{label} to #{just_file_name}",
                       'path', user_path

        missing_count = log_unmatched local_list, user_list, 'missing', :red
        extra_count = log_unmatched user_list, local_list, 'extra', :yellow

        if missing_count > 0
          log_results "#{missing_count} #{keyword} are missing", "Your ansible run will likely fail with this #{label}"
        else
          log_results 'Everything appears to be in order', "No missing #{keyword} were found"
        end

        if extra_count > 0
          log_results "#{extra_count} extra #{keyword} were detected:", "No problem but remember to add them to a future #{keyword}"
        else
          log_results "No extra #{keyword} were found:", "Extra #{keyword} are fine but you have none"
        end
      else
        log_status_top label, "Comparing this version of orats' #{label} to ???:", :blue
        log_error 'error', "Error comparing #{label}", 'path', user_path, true do
          log_status_bottom 'tip', 'Make sure you supply a file name', :white
        end
      end
    end

    def url_to_string(url)
      begin
        file_contents = open(url).read
      rescue *[OpenURI::HTTPError, SocketError] => ex
        log_error 'error', "Error browsing #{url}",
                  'message', ex
        exit 1
      end

      file_contents
    end

    def log_unmatched(compare, against, label, color)
      count = 0

      compare.each do |item|
        unless against.include?(item)
          log_status_bottom label, item, color
          count += 1
        end
      end

      count
    end

    def galaxy_file_path
      "#{File.expand_path File.dirname(__FILE__)}/templates/includes/Galaxyfile"
    end

    def inventory_file_path
      "#{File.expand_path File.dirname(__FILE__)}/templates/includes/inventory/group_vars/all.yml"
    end

    def playbook_file_path
      "#{File.expand_path File.dirname(__FILE__)}/templates/play.rb"
    end
  end
end