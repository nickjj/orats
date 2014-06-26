module Orats
  module Commands
    module Diff
      module Compare
        def remote_gem_vs_yours
          log_remote_info 'gem',
                          'Compare your orats version to the latest version',
                          'version',
                          "You have v#{VERSION} and the latest version is #{@remote_gem_version}"
        end

        def remote_vs_yours(label, remote, yours, exact_match)
          log_remote_info label,
                          "Compare your #{label} to the latest version (#{@remote_gem_version})",
                          'file', File.basename(Common::RELATIVE_PATHS[label
                                                                       .to_sym])

          outdated_and_missing = difference(remote, yours, exact_match, true)
          extras               = difference(yours, remote, exact_match)
          both_lists           = outdated_and_missing + extras
          sorted_diff          = sort_difference(both_lists).uniq { |item| item[:name] }

          if sorted_diff.empty?
            log_status_bottom 'results', 'no differences were found',
                              :magenta, true
          else
            padded_length = pad_by(sorted_diff)

            sorted_diff.each do |item|
              name    = sorted_diff.empty? ? item[:name] : item[:name].ljust(padded_length)
              version = item[:version].empty? ? '' : "#{set_color('|',
                                                                  :cyan)} #{item[:version]}"

              log_status_bottom item[:status], "#{name} #{version}",
                                item[:color], true
            end
          end
        end

        private

        def name_and_version_from_line(line)
          line.split(',')
        end

        def pad_by(sorted_diff)
          longest_role = sorted_diff.max_by { |s| s[:name].length }
          longest_role[:name].length
        end

        def sort_difference(diff_list)
          # custom sort order on the color key
          diff_list.sort_by { |item| {red:    1,
                                      yellow: 2,
                                      green:  3}[item[:color]] }
        end

        def difference(remote, yours, exact_match, missing_and_outdated = false)
          @diff_list      = []
          yours_as_string = yours.join

          if missing_and_outdated
            diff = remote - yours

            diff.each do |line|
              line_parts      = name_and_version_from_line(line)
              status          = 'outdated'
              color           = :yellow
              search_contents = exact_match ? yours : yours_as_string

              unless search_contents.include?(line_parts[0])
                status = 'missing'
                color  = :red
              end

              @diff_list.push({
                                  color:   color,
                                  status:  status,
                                  name:    line_parts[0],
                                  version: line_parts[1] || ''
                              })

            end
          else
            remote.each do |line|
              unless yours.include?(line)
                line_parts = name_and_version_from_line(line)
                status     = 'extra'
                color      = :green

                @diff_list.push({
                                    color:   color,
                                    status:  status,
                                    name:    line_parts[0],
                                    version: line_parts[1] || ''
                                })
              end
            end
          end

          @diff_list
        end
      end
    end
  end
end