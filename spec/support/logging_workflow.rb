class LoggingWorkflow
  include Visiflow::Workflow
  include Visiflow::Logging

  def self.steps
    [
      { succeed: { success: STOP } },
      { failure: { success: STOP } }
    ]
  end

  def initialize(logger: nil)
    super()
    @logger = logger
  end

  def succeed
    Visiflow::Response.success
  end

  def failure
    fail "Ouch"
  end
end
