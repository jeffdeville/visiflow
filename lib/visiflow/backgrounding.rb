module Visiflow
  module Backgrounding
    def undelay(step_name)
      step_name.to_s.split("__").last.to_sym
    end

    def delayed?(step_name)
      step_name.to_s.start_with?("delay__")
    end

    def backgrounded?
      context.is_backgrounded
    end

    # code that is run when the workflow 'wakes up'. Can be used to run
    # any step in a workflow, based on the 'step_name' provided
    def perform(step_name, env)
      context.attributes = env
      context.initial_step = step_name.to_sym
      context.is_backgrounded = true
      run step_name.to_sym
    end

    def self.perform_async(step_after_wake, attributes)
      fail "This method should invoke your background job runner"
    end
    def perform_async(step_after_wake, attributes)
      fail "You should implement this in a class method on your workflow"
    end

    # If you have an async job that you'd like to run synchronously, you can
    # run it this way
    def run_synchronously
      @run_synchronously = true
      until succeeded?
        if context.next_step
          run(context.next_step.name)
        else
          run
        end
      end
      self
    end

    private

    def handle_delayed_step(step_name)
      return step_name unless delayed?(step_name)

      context_attributes = context.attributes.reject { |k, _| k == :next_step }
      if @run_synchronously
        run(undelay(step_name))
      else
        self.class.perform_async undelay(step_name), context_attributes
      end

      Visiflow::FlowExecution::STOP
    end
  end
end
