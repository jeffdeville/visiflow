require 'spec_helper'

describe Visiflow::Workflow do
  describe "initialize" do
    context "an argument isn't defined in the context" do
      Given!(:workflow) { TestContextualWorkflow.new }
      When(:result) do
        step = workflow.processed_steps[:step_with_invalid_arg]
        workflow.execute_step step
      end
      Then { expect(result).to have_raised "missing a required parameter" }
    end
  end

  context "the arguments are defined in the context" do
    Given(:workflow) do
      TestContextualWorkflow.new(initial_values: { arg1: "initial_value" })
    end

    When { workflow.execute_step(workflow.processed_steps[:step1]) }

    Then { workflow.context.arg2 == "changed" }
    And  { workflow.context.arg3 == "new" }
  end

  context "an output key is not defined in the context" do
    Given(:workflow) do
      TestContextualWorkflow.new(initial_values: { arg1: "initial_value" })
    end
    When(:result) do
      workflow.execute_step(
        workflow.processed_steps[:step_with_invalid_output]
      )
    end
    Then do
      expect(result).to have_raised("'not_defined' not defined on context")
    end
  end
end
