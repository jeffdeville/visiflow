require 'spec_helper'

describe Visiflow::Step do
  describe "#initialize" do
    context "when initializing a final state (indicated by a symbol)" do
      Given(:step_input) { :complete }
      When(:step) { Visiflow::Step.new(step_input) }
      Then  { step.name == :complete }
      And  { step.step_map.length.should == 0 }
      And  { step.to_s == "complete" }
    end
    context "when initializing an intermediate state (indicated by a hash)" do
      Given(:step_input) do
        { step1: { success: :complete, failure: :fail_hard } }
      end
      When(:step) { Visiflow::Step.new(step_input) }
      Then  { step.name == :step1 }
      And  { step.step_map.length.should == 2 }
      And  { step[:success].should == :complete }
      And  { step[:failure].should == :fail_hard }
    end
  end

  describe "self.create_steps" do
    context "when empty" do
      Then { Visiflow::Step.create_steps([]).should == {} }
      And  { Visiflow::Step.create_steps(nil).should == {} }
    end
    context "when steps exist" do
      Given(:step_input) do
        [first_step,
         { step2: { success: :step3 } },
         :step3,
         :step1_fail_handler
         ]
      end
      context "and first step is a Symbol" do
        Given(:first_step) { :step1 }
        Given { step_input }
        When(:return_val) { Visiflow::Step.create_steps(step_input) }
        Then do
          return_val.keys.should ==
            [first_step, :step2, :step3, :step1_fail_handler]
        end
      end
      context "and first step is a Hash" do
        Given(:first_step) do
          { step1: { success: :step2,
                     failure: :step1_fail_handler } }
        end
        When(:return_val) { Visiflow::Step.create_steps(step_input) }
        Then { return_val.length.should == 4 }
        And  { return_val.class.should == Hash }
      end
    end
  end
end
