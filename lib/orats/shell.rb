require 'securerandom'
require 'open-uri'

module Orats
  module Shell
    def run_from(path, command)
      run "cd #{path} && #{command} && cd -"
    end

    def git_commit(message)
      run_from @active_path, "git add -A && git commit -m '#{message}'"
    end
  end
end