require 'spec_helper'

describe Visiflow::Workflow do
  describe "initialize" do
    context "workflows with context that does not define a last_result" do
      it "should raise in the initialization" do
        class InvalidContext
          def initialize(values)
          end
        end
        expect do
          class InvalidContextWorkflow
            include Visiflow::Workflow
            set_context InvalidContext
            def self.steps
              []
            end
          end
        end.to raise_error "Your context class must have a last_result property"
      end
    end

    context "an argument isn't defined in the context" do
      let!(:workflow) { TestContextualWorkflow.new }
      it "raises an exception" do
        expect do
          step = workflow.processed_steps[:step_with_invalid_arg]
          workflow.execute_step step
        end.to raise_error "missing a required parameter"
      end
    end
  end

  context "the arguments are defined in the context" do
    let(:workflow) do
      TestContextualWorkflow.new(initial_values: { arg1: "initial_value" })
    end

    act { workflow.execute_step(workflow.processed_steps[:step1]) }

    it "runs just fine" do
      expect(workflow.context.arg2).to eq "changed"
      expect(workflow.context.arg3).to eq "new"
    end

    it "the output available to future steps" do
      workflow.execute_step(workflow.processed_steps[:step2])
      expect(workflow.passed_in_arg2).to eq "changed"
      expect(workflow.passed_in_arg3).to eq "new"
    end
  end

  context "an output key is not defined in the context" do
    let(:workflow) do
      TestContextualWorkflow.new(initial_values: { arg1: "initial_value" })
    end
    it "raises an exception" do
      expect do
        workflow.execute_step(
          workflow.processed_steps[:step_with_invalid_output]
        )
      end.to raise_error "'not_defined' not defined on context"
    end
  end
end
