class Visiflow::Step
  include Comparable

  attr_accessor :name, :step_map
  def initialize(step)
    if step.is_a? Hash
      @name = step.keys.first
      @step_map = step[@name]

      # Verify biz rules
      if @step_map[:no_matter_what] && @step_map.length > 1
        fail ArgumentError, "When specifying a no_matter_what step, only that step can be referenced"
      end
    else
      @name = step
      @step_map = {}
    end
  end

  def [](result)
    @step_map[result]
  end

  def to_s
    name
  end

  def self.create_steps(steps_array)
    steps = Array(steps_array).map{|s| Visiflow::Step.new(s) }
    steps = steps.reduce({}){|acc, step| acc[step.name] = step; acc; }
    steps
  end

  def <=>(other)
    case other
      when Symbol
         @name == other ? 0 : -1
      when Visiflow::Step
        @name == other.name ? 0 : -1
      else
        -1
    end
  end
end
