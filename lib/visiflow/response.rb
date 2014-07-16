module Visiflow
  class Response
    include Virtus.model(constructor: false)
    attribute :status, Symbol
    attribute :values, Hash
    attribute :message, String

    # attr_reader :status, :message, :values
    def initialize(status, values = {})
      self.status = status.to_sym
      if values && values.has_key?(:message)
        self.message = values.delete :message
      end
      self.values = values
    end

    def [](key)
      values[key]
    end

    def self.method_missing(method, *args)
      status = method.to_sym
      values = (args.nil? || args.count == 0) ? nil : args.first
      values = case values
      when String then { message: values }
      else
        values
      end
      Visiflow::Response.new(status, values)
    end

    def method_missing(method, *args)
      method_string = method.to_s
      if /\?$/.match(method_string) # check if it's a [STATUS]? call
        @status == method_string.gsub("?", "").to_sym
      end
    end

    def to_s
      "#{status}: #{message}"
    end
  end
end
