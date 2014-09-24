module Visiflow::Workflow
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

  def run(starting_step = processed_steps.keys.first)
    context.next_step = determine_first_step(starting_step)
    context.initial_step = context.next_step.name
    while context.next_step
      context.last_result = execute_step context.next_step
      context.last_step = context.next_step
      next_step_name =
        determine_next_step_name(context.last_result, context.last_step)
      context.next_step = processed_steps[handle_delayed_step(next_step_name)]
    end

    self
  end

  def determine_first_step(starting_step)
    next_step = processed_steps[starting_step]
    unless next_step
      fail Visiflow::WorkflowError, starting_step,
           "Could not find step: #{starting_step} in #{processed_steps.keys}"
    end
    next_step
  end

  def assert_all_steps_defined
    unless undefined_steps.empty?
      undefined_steps_string = undefined_steps.join(', ')
      fail "#{self.class.name} has undefined steps: #{undefined_steps_string}"
    end
  end

  def undefined_steps
    results = processed_steps.values.map do |step|
      [step.name] + step.step_map.values.map do |value|
        value && value.to_s.split('__').last.to_sym
      end
    end

    results.flatten.uniq.compact.select { |step| !respond_to?(step) }
  end

  def required
    fail 'missing a required parameter'
  end

  ##############################
  # Status
  ##############################

  def succeeded?
    return false if no_steps_run?
    successful_completion_states[context.last_step.name] ==
      context.last_result.status
  end

  def no_steps_run?
    context.last_step.nil? || context.last_result.nil?
  end

  def failed?
    !succeeded?
  end

  def last_message
    last_result.message
  end

  def last_step
    context.last_step
  end

  def last_step=(value)
    context.last_step = value
  end

  def last_result
    context.last_result
  end

  def last_result=(value)
    context.last_result = value
  end

  ##############################
  # Background Jobs
  ##############################
  def undelay(step_name)
    step_name.to_s.split('__').last.to_sym
  end

  def delayed?(step_name)
    step_name.to_s.start_with?('delay__')
  end

  def backgrounded?
    context.is_backgrounded
  end

  # code that is run when the workflow 'wakes up'. Can be used to run
  # any step in a workflow, based on the 'step_name' provided
  def perform(step_name, env)
    context.attributes = env
    context.initial_step = step_name.to_sym
    context.is_backgrounded = true
    run step_name.to_sym
  end

  def self.perform_async(_step_after_wake, _attributes)
    fail 'This method should invoke your background job runner'
  end
  def perform_async(_step_after_wake, _attributes)
    fail 'You should implement this in a class method on your workflow'
  end

  # If you have an async job that you'd like to run synchronously, you can
  # run it this way
  def run_synchronously
    @run_synchronously = true
    until succeeded?
      if context.next_step
        run(context.next_step.name)
      else
        run
      end
    end
    self
  end
  ##############################
  # End Background Jobs
  ##############################

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
  def determine_next_step_name(response, current_step)
    unless response.is_a? Visiflow::Response
      fail "#{current_step.name} did not return a Visiflow::Response"
    end

    next_step_symbol =
    case
    when current_step.key?(response.status)
      current_step[response.status]
    when response.success? || response.failure?
      # It's ok to end on a success or failure response
      STOP
    else
      msg = "#{current_step.name} returned: #{response.status}, " \
        "but we can't find that outcome's step"
      fail ArgumentError, msg
    end

    next_step_symbol || STOP
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
