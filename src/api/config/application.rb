require_relative "boot"
require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "rails/test_unit/railtie"
Bundler.require(*Rails.groups)
module CourseStudio
  class Application < Rails::Application
    config.load_defaults 8.1
    config.api_only = true
    config.active_job.queue_adapter = :solid_queue
    config.solid_queue.connects_to = nil
    config.active_record.dump_schema_after_migration = false
    config.active_record.maintain_test_schema = false
    config.action_dispatch.show_exceptions = :none
    config.filter_parameters += %i[password token secret database_url test_database_url]
  end
end
