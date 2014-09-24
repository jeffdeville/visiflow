require 'visiflow'
require 'rails'
module Visiflow
  class Railtie < Rails::Railtie
    railtie_name :visiflow

    rake_tasks do
      load 'tasks/workflow.rake'

    end
  end
end
