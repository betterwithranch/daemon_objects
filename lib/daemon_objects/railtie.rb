class Railtie < Rails::Railtie
  rake_tasks do
    load File.join(DaemonObjects::ROOT, "daemon_objects/tasks/daemon_objects.rake")
  end
end if defined?(Rails)
