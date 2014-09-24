module Visiflow
  module State
    def succeeded?
      return false if no_steps_run?
      successful_completion_states[context.last_step.name] ==
        context.last_result.status
    end

    def no_steps_run?
      context.last_step.nil? || context.last_result.nil?
    end

    def failed?
      !succeeded?
    end

    def last_message
      last_result.message
    end

    def last_step
      context.last_step
    end

    def last_step=(value)
      context.last_step = value
    end

    def last_result
      context.last_result
    end

    def last_result=(value)
      context.last_result = value
    end
  end
end
