module Visiflow
  class BaseContext
    include Virtus.model
    attribute :last_result, Visiflow::Response
    attribute :last_step, Visiflow::Step
    attribute :next_step, Visiflow::Step
  end
end
