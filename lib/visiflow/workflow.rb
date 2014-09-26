module Visiflow::Workflow
  include Visiflow::State
  include Visiflow::Backgrounding
  STOP = nil

  attr_accessor :processed_steps
  def self.included(klass)
    @classes ||= []
    @classes << klass.name
    klass.extend ClassMethods
    klass.class_eval do
      attr_reader :classes
      attr_accessor :context
    end
  end

  module ClassMethods
    attr_accessor :context_class

    def context(&block)
      if block_given?
        klass = Class.new(Visiflow::BaseContext, &block)

        self.context_class = klass
      end
    end

    def delay(step_name)
      "delay__#{step_name}".to_sym
    end

    def run(initial_values = {})
      new(initial_values).run
    end
  end

  def initialize(initial_values = {})
    context_class = self.class.context_class || Visiflow::BaseContext

    self.context = context_class.new(initial_values)
    self.processed_steps = Visiflow::Step.create_steps(Array(self.class.steps))
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

  def around_step(_step_name)
    yield
  end

  BAD_STEP_RESPONSE = 'Workflow steps must return a Visiflow::Response'
  def execute_step(step)
    args = get_step_params(step.name)

    # probably should pass in the args to the around and before steps as well.
    around_step(step.name) do
      if before_step(step.name)
        result = send(step.name, *args)
        fail BAD_STEP_RESPONSE unless result.is_a? Visiflow::Response
        update_context(result.values)
        after_step(step.name, result)
      end
    end
  end

  def run(
    step = processed_steps[processed_steps.keys.first]
  )
    step = step.is_a?(Symbol) ? processed_steps[step] : step
    return self unless step

    self.next_step = step
    self.last_result = execute_step next_step

    assert_valid_last_result

    self.last_step = next_step
    run(processed_steps[handle_delayed_step(determine_next_step_name)])
  end

  def assert_all_steps_defined
    unless undefined_steps.empty?
      undefined_steps_string = undefined_steps.join(', ')
      fail "#{self.class.name} has undefined steps: #{undefined_steps_string}"
    end
  end


  def undefined_steps
    step_names.select { |step| !respond_to?(step) }
  end

  def step_names
    steps = processed_steps.values.map { |step| step.name }
    next_steps = processed_steps.values.map { |step|
      step.step_map.values.compact.map { |s| undelay(s) }
    }.flatten
    (steps + next_steps).uniq
  end

  def required
    fail 'missing a required parameter'
  end

  private

  def handle_delayed_step(step_name)
    return step_name unless delayed?(step_name)

    context_attributes = context.attributes.reject { |k, _| k == :next_step }
    if @run_synchronously
      run(undelay(step_name))
    else
      self.class.perform_async undelay(step_name), context_attributes
    end

    STOP
  end

  def assert_valid_last_result
    unless last_result.is_a? Visiflow::Response
      fail "#{current_step.name} did not return a Visiflow::Response"
    end
  end

  # There are a few 'special' response statuses, and they behave like this:
  # :success/:failure - If success or failure are returned, and there is nothing
  # to go on to, the process will simply stop. Assumption is that we are at
  # the end of the flow.
  def determine_next_step_name
    case
    when last_step.key?(last_result.status) then last_step[last_result.status]
    when last_result.success? || last_result.failure? then STOP
    else
      fail ArgumentError, "#{last_step.name} returned: #{last_result.status}, " \
        "but we can't find that outcome's step"
    end
  end

  def get_step_params(step_name)
    param_names = method(step_name).parameters.map(&:last)
    return [] if param_names.empty?
    Array.wrap(context.attributes.slice(*param_names))
  end

  def assert_all_values_in_context(values)
    keys_in_common = values.keys & context.attributes.keys
    if keys_in_common.length < values.keys.length
      missing_keys = values.keys - keys_in_common
      fail "#{missing_keys} not defined on context"
    end
  end

  def update_context(values = {})
    return unless values
    assert_all_values_in_context(values)
    values.each do |key, value|
      context.send("#{key}=", value)
    end
  end
end
