require 'spec_helper'

describe Visiflow::Logging do
  Given(:success_step) { workflow.processed_steps[:succeed] }
  Given(:fail_step) { workflow.processed_steps[:failure] }

  context "when a logger exists" do
    Given(:logger) { double }
    Given(:workflow) { LoggingWorkflow.new logger: logger }

    context "and a step succeeds" do
      Given { logger.stub(:info) }

      When(:last_result) { workflow.execute_step success_step }

      Then do
        logger.should have_received(:info)
          .with("LoggingWorkflow: [succeed] --> [success]")
      end
      And { last_result.should be_success }
    end

    context "and a step fails" do
      Given { logger.stub(:error) }
      When(:err) { workflow.execute_step fail_step }
      Then { logger.should have_received(:error) }
    end
  end

  context "when a logger is missing" do
    Given(:workflow) { LoggingWorkflow.new logger: nil }

    context "and a step succeeds" do
      When(:result) { workflow.execute_step success_step }
      Then { expect(result).to_not have_raised }
    end
  end
end
