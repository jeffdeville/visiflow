class BaseWorkflow
  include Visiflow::Workflow

  context do
    attribute :a_thing, String
  end
end

class InheritedWorkflow < BaseWorkflow
  def self.steps
    [
      :step_one
    ]
  end

  def step_one(a_thing: required)
    Visiflow::Response.success
  end
end
