module Orats
  module Play
    def play_app(path)
      return unless can_play?

      @active_path = path
      rails_template 'play'
    end

    private

    def can_play?
      log_thor_task 'shell', 'Checking for the ansible binary'

      has_ansible = run('which ansible', capture: true)

      log_error 'error', 'Cannot access ansible', 'question', 'Are you sure you have ansible setup correctly?', true do
        log_status_bottom 'tip', 'http://docs.ansible.com/intro_installation.html', :white
      end if has_ansible.empty?

      !has_ansible.empty?
    end
  end
end