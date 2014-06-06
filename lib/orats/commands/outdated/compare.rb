module Orats
  module Commands
    module Outdated
      module Compare
        def remote_to_local_gem_versions
          log_remote_info 'gem', 'Comparing this version of orats to the latest orats version',
                          'version', "Latest: #{@remote_gem_version}, Yours: v#{VERSION}"
        end

        def remote_to_local_galaxyfiles
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

        def remote_to_local(label, keyword, remote, local)
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

        def local_to_user(label, keyword, flag_path, local)
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

        private

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
  end
end