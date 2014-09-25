ENV['RAILS_ENV'] ||= 'test'

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require 'rspec/given'
require 'visiflow'
support_files = Dir[File.join(
  File.expand_path('../../spec/support/**/*.rb', __FILE__)
)]
support_files.each { |f| require f }

RSpec.configure do |config|
  config.extend(SyntaxHelpers)
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = :random
end
