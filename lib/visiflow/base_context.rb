module Visiflow
  class BaseContext
    # Virtus to:
    #   - determine which parameters should be saved to the job queue
    #   - provide type conversions for job queues that store data in json

    include Virtus.model
    attribute :last_result, Visiflow::Response
    attribute :last_step, Visiflow::Step
    attribute :next_step, Visiflow::Step
  end
end
