require 'spec_helper'

describe Visiflow::Response do
  it "should set a status w/ no message" do
    resp = Visiflow::Response.success
    expect(resp.status).to eq :success
    expect(resp.message).to be_nil
  end

  it "should set a status w/ a message" do
    resp = Visiflow::Response.success("yeehaw")
    expect(resp.status).to eq :success
    expect(resp.message).to eq "yeehaw"
  end

  it "should set a status w/ values" do
    resp = Visiflow::Response.success({message: 'message', return_val: "hi"})
    expect(resp.status).to eq :success
    expect(resp.message).to eq "message"
    expect(resp.values).to eq(return_val: "hi")
  end

  it "should know if a status is currently set" do
    resp = Visiflow::Response.success
    resp.success?.should be true
  end

end
