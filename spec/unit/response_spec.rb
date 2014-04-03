require 'spec_helper'

describe Visiflow::Response do
  it "should set a status w/ no message" do
    resp = Visiflow::Response.success
    resp.status.should == :success
    resp.message.should be_nil
  end

  it "should set a status w/ a message" do
    resp = Visiflow::Response.success("yeehaw")
    resp.status.should eq :success
    resp.message.should eq "yeehaw"
  end

  it "should know if a status is currently set" do
    resp = Visiflow::Response.success
    resp.success?.should be_true
  end

end
