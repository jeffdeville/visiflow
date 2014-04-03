# Workflows
module Visiflow::Driver
  attr_accessor :processed_steps

  def initialize(steps=nil)
    steps ||= Array(self.steps)
    # processed_steps = Array(self.steps)
    @processed_steps = Visiflow::Step.create_steps(steps)
    choose_first_step @processed_steps.keys.first
  end

  def before_step(step)
    method_name = "before_#{step}"
    return self.send(method_name) if respond_to? method_name
    true
  end

  def after_step(step, result)
    method_name = "after_#{step}"
    return self.send(method_name, result) if respond_to? method_name
    result
  end

  # This shold be configurable
  def around_step(step_name)
    return yield
  end

  def execute_step(step)
    begin
      around_step_result = around_step(step.name) do
        if before_step(step.name)
          result = self.send(step.name)
          # Can the after state cancel the flow?  if so...  I haven't done that yet.
          after_step(step.name, result)
        end
      end
      around_step_result
    rescue => e
      # Rails.logger.error "#{e.message}\n#{e.backtrace.try(:join, "\n")}"
      return Visiflow::Response.failure("Uncaught exception! \n #{e.message}\n#{e.backtrace.join("\n")}")
    end
  end

  def run(override_step = nil)
    @next_step = processed_steps[override_step] unless override_step.nil?
    while true
      break if @next_step.nil?
      self.persist_state @next_step.name

      result = execute_step @next_step
      @next_step = determine_next_step(result)
    end
  end

  # just used to verify that your workflow will handle all of its defined branches
  def all_steps_defined?
    undefined_steps = @processed_steps.values.map{|s| [s.name] + s.step_map.values }.flatten.uniq.
      find_all{|step| !(self.respond_to?(step) || step.to_s.start_with?("notify_of")) }
    # Rails.logger.error(pp undefined_steps)
    return true if undefined_steps.empty?
    false
  end

  def reload_and_continue
    # because the properties were all serialized, they will need to be refreshed.
    wakeup
    choose_first_step
    run
  end

  def roofy_the_workflow(response, run_at=nil)
    delay_until(response, run_at)
    Visiflow::Response.stop
  end

  private

  # There are a few 'special' response statuses, and they behave like this:
  #   :success - If success is returned, and there is nothing to go on to, the process will simply stop.
  #               Assumption is that we are at the end of the flow. Will probably want to hard code this to :stop at some point.
  #   :no_matter_what - This response has to be by itself. It's there so that come hell or high water, the next step following this
  #                       one is executed. It's used when you have several things that should all run, but you don't want them in
  #                       the same method because they are separate concerns.
  def determine_next_step(response)
    @current_step = @next_step
    next_step_symbol = case
      when @current_step[:no_matter_what]
        @current_step[:no_matter_what]
      when response.status == :stop then nil
      when response.status == :sleep then delay_until(response, response.message)
      when @current_step[response.status] then @current_step[response.status]
      when @current_step[response.status].nil? && (response.success? || response.failure?) then nil
      else
        msg = "#{@current_step.name} returned: #{response.status}, but we can't find that outcome's step"
        p msg
        raise ArgumentError, msg
    end
    next_step_symbol ? @processed_steps[next_step_symbol] : nil
  end

  # Todo: remove this steps_array - it's here because once @steps is made, I don't
  # know which step was defined first because ruby 1.8 is pissy like that.
  def choose_first_step(first_step=nil)
    last_run_step = self.state #load_state
    @next_step = last_run_step ? @steps[last_run_step] : first_step
  end

  def delay_until(response, run_at=nil)
    step_after_awakening = @next_step[response.status]
    self.persist_state(step_after_awakening)
    if run_at
      # require 'pry'; binding.pry
      options = {:run_at => run_at}
      delay(options).reload_and_continue
    else
      delay.reload_and_continue
    end
    nil
  end

  def delay(options = {})
    self
  end

end
