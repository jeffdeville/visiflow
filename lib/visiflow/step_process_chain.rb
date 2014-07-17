# Not yet used.  Would be a nice facility to add, but not needed yet.
module Visiflow
  class StepProcessChain
    DIVIDER = "__"
    attr_accessor :step_processors

    def initialize(step_name, step_processors = {})
      self.step_name = step_name
      self.step_processors = step_processors
    end

    def halt?
      @halt
    end

    # Peels off process directives from the front of the step name.
    # eg:
    #   "step_name" would do nothing
    #   "delay.step_name" would first delay, and then stop
    #   "delay.phone_home.step_name" would first delay, then phone_home, then yield the step
    def process_step(step_name)
      process_directive, *tail = step_name.split(DIVIDER)
      return self if tail.empty?  # Base case
      fail "Missing Processor for #{process_directive}" unless processors[process_directive]

      response = processors[process_directive].process(tail.join(DIVIDER))
      self.halt ||= response.halt_workflow?
      return self unless response.continue_processing? # A processor can disable further processing of a step

      # recursively apply processors until there's only the step left
      process_step(tail.join("."))
    end

    def root_step_name
      step_name.split(".").last
    end
  end

  class ProcessorResponse < Struct.new(:halt_workflow, :halt_step_processor)
    def self.halt_workflow
      ProcessorResponse.new(true, false)
    end
    def self.halt_step_processor
      ProcessorResponse.new(false, true)
    end
    def self.continue
      ProcessorResponse.new(false, false)
    end

    def halt_workflow?
      halt_workflow
    end
    def halt_step_processor?
      halt_step_processor
    end
  end

  module DelayProcessor
    PROCESS_DIRECTIVE = "delay"
    def process(remaining_step_name)
      # do the perform async w/ this remaining step name
      # will need access to the workflow's state also.

      ProcessorResponse.halt_workflow
    end
  end
end
