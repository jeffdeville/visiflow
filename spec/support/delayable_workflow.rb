class DelayableWorkflow
  include Visiflow::Workflow

  context do
    attribute :something_persisted, String
  end

  attr_accessor :not_persisted, :delayable_next_step, :delayable_params

  def self.steps
    [
      {
        process_one: {
          success: delay(:process_two)
        }
      },
      :process_two
    ]
  end

  def process_one(something_persisted: required)
    # save this so we can test if it ran
    self.not_persisted = "in_process"
    Visiflow::Response.success(something_persisted: "in_process")
  end

  def process_two(something_persisted: required)
    # save this so we can test if it ran
    self.not_persisted = "delayed_process"
    Visiflow::Response.success(something_persisted: "delayed_process")
  end
end
