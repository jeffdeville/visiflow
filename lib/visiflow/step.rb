class Visiflow::Step
  attr_accessor :name, :step_map

  def initialize(step_definition)
    if step_definition.is_a? Hash
      build_from_hash step_definition
    else
      self.name = step_definition.to_sym
      self.step_map = {}
    end
  end

  def [](result)
    step_map[result]
  end

  def key?(result)
    step_map.key?(result)
  end

  def to_s
    name
  end

  def self.create_steps(steps_array)
    Array(steps_array)
    .map{|s| Visiflow::Step.new(s) }
    .each_with_object({}){|step, acc| acc[step.name] = step }
  end

  private

  def build_from_hash(step_definition)
    if step_definition.size > 1
      # rubocop:disable LineLength
      fail ArgumentError, "Use only one key-value pair when specifying a step"
    end

    self.name, self.step_map = step_definition.first

    # Verify biz rules
    if step_map[:no_matter_what] && step_map.size > 1
      # rubocop:disable LineLength
      fail ArgumentError, "When specifying a no_matter_what step, only that step can be referenced"
    end
  end
end
