module Visiflow
  module Logging
    attr_writer :logger

    def around_step(step_name)
      result = super(step_name) do
        yield
      end
      @logger.info "#{self.class.name}: [#{step_name}] " \
        "--> [#{result.status}]" if @logger
      result
    rescue => error
      @logger.error Visiflow::StepError.new(error, step_name) if @logger
      raise error
    end
  end
end
