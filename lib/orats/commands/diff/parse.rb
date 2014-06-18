module Orats
  module Commands
    module Diff
      module Parse
        def gem_version
          "v#{url_to_string(@remote_paths[:version]).match(/'(.*)'/)[1..-1].first}"
        end

        def galaxyfile(contents)
          contents.split
        end

        def hosts(contents)
          contents.scan(/^\[.*\]/)
        end

        def inventory(contents)
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

        def playbook(contents)
          roles = contents.scan(/^.*role:.*/)

          roles.map! do |line|
            line.strip! if line.include?(' ') || line.include?("\n")

            role_parts = line.split('role:')

            # start at the actual role name
            line       = role_parts[1]

            if line.include?(',')
              line = line.split(',').first
            end

            line.strip! if line.include?(' ')
          end

          roles.uniq
        end
      end
    end
  end
end