require 'spec_helper'

describe Visiflow::Workflow do
  subject(:workflow) { TestWorkflow.new }

  describe ".run" do
    it "creates a new workflow with the arguments and runs it" do
      expect(TestWorkflow).to receive(:new).with(foo: 123).and_return(workflow)
      expect(workflow).to receive(:run)

      TestWorkflow.run(foo: 123)
    end

    it "returns the workflow" do
      expect(TestWorkflow.run).to be_a(TestWorkflow)
    end
  end

  describe "before_step" do
    context "when a before_step is defined" do
      act(:response) { workflow.before_step(:step1) }
      specify { workflow.before_step1_called.should be true }
    end

    context "when a before_step is NOT defined" do
      act(:response) { workflow.before_step(:step2) }
      it "should return true to prevent canceling the workflow" do
        response.should be true
      end
    end
  end

  describe "after_step" do
    context "when a after_step is defined" do
      act(:response) do
        workflow.after_step(:step1, Visiflow::Response.success)
      end
      specify { workflow.after_step1_called.should be true }
    end

    context "when a after_step is NOT defined" do
      act(:response) do
        workflow.after_step(:step2, Visiflow::Response.success)
      end
      it "should return true to prevent canceling the workflow" do
        response.should be_truthy
      end
    end
  end

  describe "run" do
    context "when first step does not exist" do
      it "should raise" do
        expect { workflow.run(:i_do_not_exist) }
          .to raise_error Visiflow::WorkflowError
      end
    end

    context "when all steps' results are success" do
      act(:ran_workflow) { workflow.run }

      it "proceeded through the expected flow" do
        workflow.execution_path.should =~ [:step1, :step2, :step3]
      end

      it "should know it succeeded" do
        workflow.should be_succeeded
      end

      it "returns the workflow" do
        ran_workflow.should eq(workflow)
      end
    end

    context "when a step fails" do
      act { workflow.run(:step_that_fails) }

      it "the expected flow should include the passed spec and failed one" do
        workflow.execution_path.should =~ [:step_that_fails, :fail_handler]
      end

      it "should know it failed" do
        workflow.should be_failed
      end
    end

    context "when the initial step is not the first one" do
      act { workflow.run(:step2) }
      it "should have skipped step1" do
        workflow.execution_path.should =~ [:step2, :step3]
      end
    end
  end

  describe "#determine_next_step" do
    # describe ":no_matter_what exists" do
    #   context "and another step also exist" do
    #     let(:crappy_steps) do
    #       [{ raising_part_one_of_two: {
    #         no_matter_what: :does_not_matter,
    #         this_breaks: :everything }
    #       }]
    #     end
    #     # rubocop:disable LineLength
    #     it "should raise when it realizes that a no_matter_what step exists w/ any other step result" do
    #       -> { TestWorkflow.new(crappy_steps) }.should raise_error
    #     end
    #   end
    #   context "when no other step exists" do
    #     act(:result) { workflow.run(:part_one_of_two) }
    #     it "runs the no_matter_what step" do
    #       workflow.execution_path.should include(:part_two_of_two)
    #     end
    #   end
    #   context "even if an exception occurs" do
    #     act(:result) { workflow.run(:raising_part_one_of_two) }
    #     it "runs the no_matter_what step" do
    #       workflow.execution_path.should include(:part_two_of_two)
    #     end
    #   end
    # end
  end

  describe "#last_message" do
    before do
      workflow.stub last_result: double(Visiflow::Response, message: "foo")
    end

    it "returns the message from the last result" do
      expect(workflow.last_message).to eq("foo")
    end
  end

  describe ".current_state" do
    let(:workflow) do
      DelayableWorkflow.new
    end

    act(:response) { workflow.run }

    it "should have persisted all of the visiflow attributes" do
      expect(workflow.delayable_params[:something_persisted])
        .to eq "in_process"
    end

    it "should not have persisted any other attributes" do
      expect(workflow.delayable_params[:not_persisted]).to be_nil
    end

    it "should have persisted the next step to run" do
      expect(workflow.delayable_next_step).to eq "process_two"
    end
  end

  describe ".resume_state" do
    let(:workflow) { DelayableWorkflow.new }
    let(:attributes) do
      { something_persisted: "from sleep" }
    end
    act { workflow.perform("delayed_process", attributes) }
    specify { expect(workflow.something_persisted).to eq "from sleep" }
  end

end
