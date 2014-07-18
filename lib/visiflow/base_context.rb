class BaseContext
  include Virtus.model
  attribute :last_result, Visiflow::Response
end
