class DelayableWorkflow
  include Visiflow::Workflow
  attribute :something_persisted, String
  attr_accessor :not_persisted, :delayable_next_step, :delayable_params

  def self.steps
    [
      { process_one: {
          success: :delay__process_two,
        }
      },
      :process_two
    ]
  end

  def process_one
    # save this so we can test if it ran
    self.not_persisted = self.something_persisted = "in_process"
    Visiflow::Response.success
  end

  def process_two
    # save this so we can test if it ran
    self.not_persisted = self.something_persisted = "delayed_process"
    Visiflow::Response.success
  end
end
