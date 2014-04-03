require 'spec_helper'

describe Visiflow::Step do
  describe "#initialize" do
    context "when initializing a final state (indicated by a symbol)" do
      let(:step_input) { :complete }
      act(:step) { Visiflow::Step.new(step_input) }
      specify { step.is_a? Hash }
      specify { step.name == :complete }
      specify { step.step_map.length.should == 0 }
    end
    context "when initializing an intermediate state (indicated by a hash)" do
      let(:step_input) { {:step1 => {:success => :complete, :failure => :fail_hard} } }
      act(:step) { Visiflow::Step.new(step_input) }
      specify { step.is_a? Hash }
      specify { step.name == :step1 }
      specify { step.step_map.length.should == 2 }
      specify { step[:success].should == :complete }
      specify { step[:failure].should == :fail_hard }
    end
  end

  describe "<=>" do
    let(:step1) { Visiflow::Step.new :step1 }
    let(:step1_hash) { Visiflow::Step.new({:step1 => {:success => :complete} }) }
    let(:step2) { Visiflow::Step.new :step2 }
    let(:step2_hash) { Visiflow::Step.new({:step2 => {:success => :complete} })}

    specify { (step1 <=> step1_hash).should == 0 }
    specify { (step1 <=> :step1).should == 0 }
    specify { (step1 <=> step2).should_not == 0 }
    specify { (step1 <=> step2_hash).should_not == 0 }
  end

  describe "self.create_steps" do
    context "when empty" do
      specify { Visiflow::Step.create_steps([]).should == {} }
      specify { Visiflow::Step.create_steps(nil).should == {} }
    end
    context "when steps exist" do
      let(:step_input) {
        [first_step,
        {:step2 => {:success => :step3 } },
         :step3,
         :step1_fail_handler
        ]
      }
      context "and first step is a Symbol" do
        let(:first_step) { :step1 }
        before { step_input }
        act(:return_val) { Visiflow::Step.create_steps(step_input) }
        specify { return_val.keys.should == [first_step, :step2, :step3, :step1_fail_handler] }
      end
      context "and first step is a Hash" do
        let(:first_step) do
          {:step1 => {:success => :step2,
                      :failure => :step1_fail_handler}}
        end
        act(:return_val) { Visiflow::Step.create_steps(step_input) }
        specify { return_val.length.should == 4 }
        specify { return_val.class.should == Hash }
      end
    end
  end
end
