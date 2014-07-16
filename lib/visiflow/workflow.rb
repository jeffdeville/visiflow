module Visiflow::Workflow
  STOP = nil


  attr_accessor :processed_steps
  def self.included(klass)
    @classes ||= []
    @classes << klass.name
    klass.extend ClassMethods
    # Virtus to:
    #   - determine which parameters should be saved to the job queue
    #   - provide type conversions for job queues that store data in json
    klass.class_eval do
      include Virtus.model(constructor: false)
      attr_reader :classes
      attr_accessor :context
    end
  end

  module ClassMethods
    attr_accessor :context_class
    CONTEXT_MISSING_LAST_RESULT = "Your context class must have a last_result property"
    def set_context(klass)
      fail CONTEXT_MISSING_LAST_RESULT unless klass.instance_methods.include? :last_result
      self.context_class = klass
    end

    def delay(step_name)
      "delay__#{step_name}".to_sym
    end

    def run(initial_values={})
      new(initial_values).run
    end
  end

  def initialize(initial_values={})
    fail "You must call `set_context CLASS_NAME` in your workflow" unless self.class.context_class
    self.context = self.class.context_class.new(initial_values)
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

  def around_step(step_name)
    yield
  end

  BAD_STEP_RESPONSE = "Workflow steps must return a Visiflow::Response"
  def execute_step(step)
    args = get_step_params(step.name)

    # probably should pass in the args to the around and before steps as well.
    around_step(step.name) do
      if before_step(step.name)
        result = args ? send(step.name, args) : send(step.name)
        fail BAD_STEP_RESPONSE unless result.is_a? Visiflow::Response
        update_context(result.values)
        after_step(step.name, result)
      end
    end
  end

  def run(starting_step = processed_steps.keys.first)
    next_step = determine_first_step(starting_step)
    while next_step
      context.last_result = execute_step next_step
      context.last_step = next_step
      next_step = determine_next_step(context.last_result, context.last_step)
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
    undefined_steps = processed_steps.values.map do |s|
      [s.name] + s.step_map.values.map do |value|
        value && value.to_s.split("__").last.to_sym
      end
    end
    undefined_steps = undefined_steps.flatten.uniq.compact
      .select { |step| !respond_to?(step) }
    unless undefined_steps.empty?
      undefined_steps_string = undefined_steps.join(", ")
      fail "#{self.class.name} has undefined steps: #{undefined_steps_string}"
    end
  end

  def required
    fail "missing a required parameter"
  end

  ##############################
  # Status
  ##############################

  def succeeded?
    successful_completion_states[context.last_step.name] == context.last_result.status
  end

  def failed?
    !succeeded?
  end

  def last_message
    last_result.message
  end

  def last_step
    self.context.last_step
  end
  def last_step=(value)
    self.context.last_step = value
  end

  def last_result
    self.context.last_result
  end
  def last_result=(value)
    self.context.last_result = value
  end

  ##############################
  # Background Jobs
  ##############################
  def undelay(step_name)
    step_name.to_s.split("__").last.to_sym
  end

  def delayed?(step_name)
    step_name.to_s.start_with?("delay__")
  end

  # code that is run when the workflow 'wakes up'. Can be used to run
  # any step in a workflow, based on the 'step_name' provided
  def perform(step_name, env)
    self.context.attributes = env
    run step_name.to_sym
  end

  def perform_async(step_after_wake, attributes)
    fail "This method should invoke your background job runner"
  end
  ##############################
  # End Background Jobs
  ##############################

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

    # This is hacky, and should be replaced with a StepProcessChain instead,
    # though not in this method...
    if delayed?(next_step_symbol)
      self.class.perform_async(undelay(next_step_symbol), context.attributes)
      return STOP
    end

    next_step_symbol ? processed_steps[next_step_symbol] : STOP
  end

  def get_step_params(step_name)
    return nil if self.method(step_name).parameters.empty?
    ({}).tap do |step_params|
      self.method(step_name).parameters.each do |type, name|
        if context.attributes.has_key? name
          step_params[name] = context.attributes[name]
        end
      end
    end
  end

  def update_context(values={})
    # return unless result.values
    (values || {}).each do |key, value|
      if context.attributes.has_key? key
        context.send("#{key.to_s}=", value)
      else
        fail "'#{key}' not defined on context"
      end
    end
  end
end
