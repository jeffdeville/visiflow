class TestContextualWorkflowContext < Visiflow::BaseContext
  attribute :arg1, String
  attribute :arg2, String
  attribute :arg3, String
end

class TestContextualWorkflow
  include Visiflow::Workflow
  set_context TestContextualWorkflowContext

  def self.steps
    [
      { step1: { success: :step2 } },
      :step2,
      :step_with_invalid_arg,
      :step_with_invalid_output
    ]
  end

  def step1(arg1: required, arg2: required)
    Visiflow::Response.success(arg2: "changed", arg3: "new")
  end

  def step_with_invalid_arg(not_defined: required)
  end

  def step_with_invalid_output
    Visiflow::Response.success not_defined: "oops"
  end

  attr_accessor :passed_in_arg2, :passed_in_arg3
  def step2(arg2: required, arg3: required)
    self.passed_in_arg2 = arg2
    self.passed_in_arg3 = arg3
    return Visiflow::Response.success
  end
end
