module Visiflow::Workflow
  STOP = nil

  attr_accessor :processed_steps, :last_step, :last_result
  def self.included(base)
    @classes ||= []
    @classes << base.name
    base.extend ClassMethods
  end

  class << self
    attr_reader :classes
  end

  module ClassMethods
    def run(*args)
      new(*args).run
    end
  end

  def initialize(steps = nil)
    steps ||= Array(self.class.steps)
    self.processed_steps = Visiflow::Step.create_steps(steps)
    assert_all_steps_defined
  end

  def before_step(step)
    method_name = "before_#{step}"
    return send(method_name) if respond_to? method_name
    true
  end

  def after_step(step, result)
    method_name = "after_#{step}"
    return send(method_name, result) if respond_to? method_name
    result
  end

  def around_step(step_name)
    yield
  end

  def execute_step(step)
    around_step(step.name) do
      if before_step(step.name)
        result = send(step.name)
        after_step(step.name, result)
      end
    end
  # rescue => e # TODO: give the response the error
  #   return Visiflow::Response.failure(
  #     "Uncaught exception! \n #{e.message}\n#{e.backtrace.join("\n")}")
  end

  def run(starting_step = processed_steps.keys.first)
    next_step = determine_first_step(starting_step)
    while next_step
      self.last_result = execute_step next_step
      self.last_step = next_step
      next_step = determine_next_step(last_result, last_step)
    end

    self
  end

  def determine_first_step(starting_step)
    next_step = processed_steps[starting_step]
    unless next_step
      fail Visiflow::WorkflowError,
        "Could not find step: #{starting_step} in #{processed_steps.keys}"
    end
    next_step
  end

  def assert_all_steps_defined
    undefined_steps = processed_steps.values.map do |s|
      [s.name] + s.step_map.values
    end
    undefined_steps = undefined_steps.flatten.uniq.compact
      .select{|step| !respond_to?(step) }
    unless undefined_steps.empty?
      undefined_steps_string = undefined_steps.join(", ")
      fail "#{self.class.name} has undefined steps: #{undefined_steps_string}"
    end
  end

  def succeeded?
    successful_completion_states[last_step.name] == last_result.status
  end

  def failed?
    !succeeded?
  end

  def last_message
    last_result.message
  end

  private

  # There are a few 'special' response statuses, and they behave like this:
  #   :success - If success is returned, and there is nothing to go on to,
  #      the process will simply stop. Assumption is that we are at the end
  #      of the flow.
  #   :no_matter_what - This response has to be by itself. It's there so
  #      that come hell or high water, the next step following this
  #      one is executed. It's used when you have several things that should
  #      all run, but you don't want them in the same method because they
  #      are separate concerns.
  # rubocop:disable CyclomaticComplexity
  # rubocop:disable MethodLength
  def determine_next_step(response, current_step)
    if current_step[:no_matter_what]
      return processed_steps[current_step[:no_matter_what]]
    end

    unless response.is_a? Visiflow::Response
      fail "#{current_step.name} did not return a Visiflow::Response"
    end
    next_step_symbol =
      case
      when current_step.key?(response.status)
        current_step[response.status]
      when response.success? || response.failure?
        nil
      else
        # rubocop:disable LineLength
        msg = "#{current_step.name} returned: #{response.status}, but we can't find that outcome's step"
        p msg
        fail ArgumentError, msg
      end
    next_step_symbol ? processed_steps[next_step_symbol] : nil
  end
end
