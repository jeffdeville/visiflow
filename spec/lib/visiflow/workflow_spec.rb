require 'spec_helper'

describe Visiflow::Workflow do
  subject(:workflow) { TestWorkflow.new }

  describe '.run' do
    When(:result) { TestWorkflow.run(foo: 123) }
    Then  { result.is_a? TestWorkflow }
  end

  describe 'before_step' do
    context 'when a before_step is defined' do
      When(:response) { workflow.before_step(:step1) }
      Then { workflow.before_step1_called.should be true }
    end

    context 'when a before_step is NOT defined' do
      When(:response) { workflow.before_step(:step2) }
      Then { response == true } # to prevent canceling the workflow
    end
  end

  describe 'after_step' do
    context 'when a after_step is defined' do
      When(:response) do
        workflow.after_step(:step1, Visiflow::Response.success)
      end
      Then { workflow.after_step1_called.should be true }
    end

    context 'when a after_step is NOT defined' do
      When(:response) do
        workflow.after_step(:step2, Visiflow::Response.success)
      end
      Then { response.success? } # to prevent canceling the workflow
    end
  end

  describe 'run' do
    context "when all steps' results are success" do
      When(:ran_workflow) { workflow.run }
      Then { workflow.execution_path.should =~ [:step1, :step2, :step3] }
      And  { workflow.should be_succeeded }
      And  { ran_workflow.should eq(workflow) }
    end

    context 'when a step fails' do
      When { workflow.run(:step_that_fails) }

      it 'the expected flow should include the passed spec and failed one' do
        workflow.execution_path.should =~ [:step_that_fails, :fail_handler]
      end

      it 'should know it failed' do
        workflow.should be_failed
      end
    end

    context 'when the initial step is not the first one' do
      When { workflow.run(:step2) }
      Then { workflow.execution_path.should =~ [:step2, :step3] } # skip step1
    end
  end

  describe '#last_message' do
    Given do
      workflow.stub last_result: double(Visiflow::Response, message: 'foo')
    end
    Then { expect(workflow.last_message).to eq('foo') }
  end

  describe '.current_state' do
    Given(:workflow) { DelayableWorkflow.new }
    Given { DelayableWorkflow.stub(:perform_async) }

    When(:response) { workflow.run }

    Then do
      # persisted visiflow context
      expect(DelayableWorkflow)
        .to have_received(:perform_async)
        .with(:process_two,
              something_persisted: 'in_process',
              last_step: workflow.last_step,
              last_result: workflow.last_result,
              initial_step: nil,
              is_backgrounded: false)
    end
  end

  describe '.resume_state' do
    Given(:workflow) { DelayableWorkflow.new }
    Given(:attributes) do
      { something_persisted: 'from sleep' }
    end
    When { workflow.perform('process_two', attributes) }
    Then { expect(workflow.context.something_persisted).to eq 'delayed_process' }
    And { expect(workflow.context.initial_step).to eq :process_two }
    And { expect(workflow).to be_backgrounded }
  end

  describe '.run_synchronously' do
    Given(:workflow) { DelayableWorkflow.new }
    When { workflow.run_synchronously }
    Then { workflow.last_step.name.should == :process_two }
  end

  describe '#perform_async' do
    Given(:non_async_workflow) { TestWorkflow }
    When(:result) { non_async_workflow.perform_async }
    Then { result.should have_raised }
  end

  describe '.perform_async' do
    Given(:non_async_workflow) { TestWorkflow.new }
    When(:result) { non_async_workflow.perform_async }
    Then { result.should have_raised }
  end
end
