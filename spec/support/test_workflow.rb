class TestWorkflow
  include Visiflow::Driver
  attr_reader :before_step1_called, :after_step1_called, :execution_path, :log_results, :ex
  attr_accessor :state

  def initialize(steps = nil)
    default_steps = [
      { step1: { success: :step2,
                 failure: :step1_fail_handler }
        },

      { step2: { success: :step3 } },

      :step3,

      { step_that_fails: {
      failure: :fail_handler } },

      :step_that_raises,

      :fail_handler,

      { part_one_of_two: { no_matter_what: :part_two_of_two } },
      { raising_part_one_of_two: { no_matter_what: :part_two_of_two } },

      :part_two_of_two,
      :some_other_fail_handler,
    ]
    super(steps || default_steps)
    @execution_path = []
    @log_results = []
  end

  def before_step1
    @before_step1_called = true
  end

  def after_step1(result)
    @after_step1_called = true
    result
  end

  %w(step1 step2 step3 part_one_of_two part_two_of_two raising_part_one_of_two).each do |name|
    class_eval do
      define_method name do
        @execution_path << name.to_sym
        Visiflow::Response.success
      end
    end
  end

  def step_that_fails
    @execution_path << :step_that_fails
    Visiflow::Response.failure("something broke")
  end

  def step_that_raises
    fail StandardError, "I raised because I am not well-behaved."
  end

  def fail_handler
    @execution_path << :fail_handler
    Visiflow::Response.success # failure("something broke")
  end

  def log_result(name, result, timing)
    @log_results << { name: name.to_s, result: result.status, message: result.message, timing: timing }
  end

  def log_error(name, ex)
    @ex = ex
  end
end
