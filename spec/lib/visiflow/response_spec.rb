require 'spec_helper'

describe Visiflow::Response do

  context "should set a status w/ no message" do
    When(:resp) { Visiflow::Response.success }
    Then { resp.status == :success }
    And  { resp.success? }
    And  { resp.message.nil? }
  end

  context "should set a status w/ a message" do
    When(:resp) { Visiflow::Response.success("yeehaw") }
    Then { resp.status == :success }
    And  { resp.message == "yeehaw" }
  end

  context "should set a status w/ values" do
    When(:resp) do
      Visiflow::Response.success(message: 'message', return_val: "hi")
    end
    Then { resp.status == :success }
    And  { resp.message == "message" }
    And  { resp.values == { return_val: "hi" } }
  end
end
