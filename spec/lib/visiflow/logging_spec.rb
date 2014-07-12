require 'spec_helper'
describe Visiflow::Logging do
  let(:success_step) { subject.processed_steps[:succeed] }
  let(:fail_step) { subject.processed_steps[:failure] }

  context "when a logger exists" do
    let(:logger) { double }
    subject { LoggingWorkflow.new logger: logger }

    context "and a step succeeds" do
      before { logger.stub(:info) }
      act(:last_result) { subject.execute_step success_step }

      it "should have logged the completion of the step" do
        logger.should have_received(:info)
          .with("LoggingWorkflow: [succeed] --> [success]")
      end

      it "should have returned the visiflow result to the caller" do
        last_result.should be_success
      end
    end

    context "and a step fails" do
      before { logger.stub(:error) }
      # subject { LoggingWorkflow.new logger: logger }
      act(:err) do
        begin
          subject.execute_step fail_step
        rescue => err
          err
        end
      end

      it "should have logged the completion of the step" do
        logger.should have_received(:error) do |error|
          expect(error).to be_a Visiflow::Error
        end
      end
      specify { err.message.should eq "Ouch" }
    end
  end

  context "when a logger is missing" do
    subject { LoggingWorkflow.new logger: nil }

    context "and a step succeeds" do
      it "should not raise because of a missing logger" do
        expect { subject.execute_step  success_step }.not_to raise_error
      end
    end

    context "and a step fails" do
      act(:err) do
        begin
          subject.execute_step fail_step
        rescue => err
          err
        end
      end
      specify { err.message.should eq "Ouch" }
    end
  end
end
