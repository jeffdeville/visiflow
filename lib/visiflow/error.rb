module Visiflow
  class WorkflowError < StandardError
    attr_accessor :step_name

    def initialize(step_name = nil, message = nil)
      @step_name = step_name
      @message = message
    end
  end

  class StepError < StandardError
    attr_accessor :inner_exception, :step_name

    def initialize(inner_exception, step_name)
      @inner_exception = inner_exception
      @step_name = step_name
    end
  end
end
