module Orats
  # execute various shell commands
  module Shell
    def run_from(path, command)
      run "cd #{path} && #{command} && cd -"
    end

    def commit(message)
      run_from @target_path, "git add -A && git commit -m '#{message}'"
    end
  end
end
