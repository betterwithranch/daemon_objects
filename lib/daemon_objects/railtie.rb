class Railtie < Rails::Railtie
  rake_tasks do
    require "daemon_objects/loader"
    load File.join(File.dirname(__FILE__), "rake.rb")
  end
end if defined?(Rails)
