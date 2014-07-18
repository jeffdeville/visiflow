require 'spec_helper'

describe Visiflow::Workflow do
  describe "initialize" do
    context "workflows with no context" do
      class ContextlessWorkflow
        include Visiflow::Workflow
        def self.steps
          []
        end
      end

      it "should fail to initialize" do
        expect { ContextlessWorkflow.new }.to raise_error "A context must be defined on the workflow"
      end
    end

    context "workflows with nil context" do
      class NilContextlessWorkflow
        include Visiflow::Workflow
        attr_accessor :context
        def self.steps
          []
        end

        def initialize
          self.context = nil
          super
        end
      end

      it "should raise in initialization" do
        expect { NilContextlessWorkflow.new }.to raise_error "Context must be initialized"
      end
    end

    context "workflows with context that does not define a last_result" do
      class InvalidContextWorkflow
        include Visiflow::Workflow
        attr_accessor :context
        def self.steps
          []
        end

        def initialize
          self.context = "I am a lousy context"
          super
        end
      end

      it "should raise in the initialization" do
        expect { InvalidContextWorkflow.new }.to raise_error "Your context class must have a last_result property"
      end
    end

    context "an argument isn't defined in the context" do
      let!(:workflow) { TestContextualWorkflow.new }
      it "raises an exception" do
        expect {
          step = workflow.processed_steps[:step_with_invalid_arg]
          workflow.execute_step step
        }.to raise_error "missing a required parameter"
      end
    end
  end

  context "the arguments are defined in the context" do
    let(:workflow) do
      workflow = TestContextualWorkflow.new(initial_values: { arg1: "initial_value" })
      workflow
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
      expect {
        workflow.execute_step(workflow.processed_steps[:step_with_invalid_output])
      }.to raise_error "'not_defined' not defined on context"
    end
  end
end
