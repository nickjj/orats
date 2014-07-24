module Orats
  # manage detecting processes
  module Process
    def exit_if_process(detect_method, *processes)
      result = process_detect(detect_method)

      processes.each do |process|
        task "Check if #{process} is available"

        exit 1 if process_unusable?("#{result} #{process}", process)
      end
    end

    private

    def process_detect(method)
      if method == :not_found
        'which'
      elsif method == :not_running
        'ps cax | grep'
      end
    end

    def process_unusable?(command, process)
      out = run(command, capture: true)

      if out.empty?
        error "Cannot detect #{process}",
              'trying to do `which` on it'
      end

      out.empty?
    end
  end
end
