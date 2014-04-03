module Visiflow
  class Response
    attr_reader :status, :message
    def initialize(status, message = nil)
      @status = status.to_sym
      @message = message
    end

    # This method would actually be caught by method_missing, but is included for clarify
    def self.sleep(sleep_duration)
      Visiflow::Response.new(:sleep, sleep_duration)
    end

    def self.method_missing(method, *args)
      status = method.to_sym
      message = (args.nil? || args.count == 0) ? nil : args.first
      Visiflow::Response.new(status, message)
    end

    def method_missing(method, *args)
      method_string = method.to_s
      if /\?$/.match(method_string) # check if it's a [STATUS]? call
        @status == method_string.gsub("?", "").to_sym
      end
    end
  end
end
