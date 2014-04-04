require 'spec_helper'

describe Visiflow::Driver do
  describe "before_step" do
    let(:workflow) { TestWorkflow.new }

    context "when a before_step is defined" do
      act(:response) { workflow.before_step(:step1) }
      specify { workflow.before_step1_called.should be_true }
    end

    context "when a before_step is NOT defined" do
      act(:response) { workflow.before_step(:step2) }
      it "should return true to prevent canceling the workflow" do
        response.should be_true
      end
    end
  end

  describe "after_step" do
    let(:workflow) { TestWorkflow.new }

    context "when a after_step is defined" do
      act(:response) do
        workflow.after_step(:step1, Visiflow::Response.success)
      end
      specify { workflow.after_step1_called.should be_true }
    end

    context "when a after_step is NOT defined" do
      act(:response) do
        workflow.after_step(:step2, Visiflow::Response.success)
      end
      it "should return true to prevent canceling the workflow" do
        response.should be_true
      end
    end
  end

  describe "run" do
    context "when all steps' results are success" do
      let(:workflow) { TestWorkflow.new }
      act { workflow.run }

      it "proceeded through the expected flow" do
        workflow.execution_path.should =~ [:step1, :step2, :step3]
      end
    end

    context "when a step fails" do
      let(:workflow) { TestWorkflow.new }

      act { workflow.run(:step_that_fails) }

      it "the expected flow should include the passed spec and failed one" do
        workflow.execution_path.should =~ [:step_that_fails, :fail_handler]
      end
    end

    context "when the initial step is not the first one" do
      let(:workflow) { TestWorkflow.new }
      act { workflow.run(:step2) }
      it "should have skipped step1" do
        workflow.execution_path.should =~ [:step2, :step3]
      end
    end
  end

  describe "#determine_next_step" do
    describe ":no_matter_what exists" do
      context "and another step also exist" do
        let(:crappy_steps) do
          [{ raising_part_one_of_two: {
            no_matter_what: :does_not_matter,
            this_breaks: :everything }
          }]
        end
        # rubocop:disable LineLength
        it "should raise when it realizes that a no_matter_what step exists w/ any other step result" do
          -> { TestWorkflow.new(crappy_steps) }.should raise_error
        end
      end
      context "when no other step exists" do
        let(:workflow) { TestWorkflow.new }
        act(:result) { workflow.run(:part_one_of_two) }
        it "runs the no_matter_what step" do
          workflow.execution_path.should include(:part_two_of_two)
        end
      end
      context "even if an exception occurs" do
        let(:workflow) { TestWorkflow.new }
        act(:result) { workflow.run(:raising_part_one_of_two) }
        it "runs the no_matter_what step" do
          workflow.execution_path.should include(:part_two_of_two)
        end
      end
    end

    context ":success step with nothing following" do
      let(:workflow) { TestWorkflow.new [:step1] }
      act(:next_step) { workflow.run }
      specify { next_step.should be_nil }
    end

    context ":failure step with nothing following" do
      let(:workflow) { TestWorkflow.new [:step_that_fails] }
      act(:next_step) { workflow.run }
      specify { next_step.should be_nil }
    end
  end
end
