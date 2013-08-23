class Railtie < Rails::Railtie
  rake_tasks do
    require "daemon_objects/loader"
    load File.join(File.dirname(__FILE__), "tasks/daemon_objects.rake")
  end
end if defined?(Rails)
