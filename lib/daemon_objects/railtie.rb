class Railtie < Rails::Railtie
  rake_tasks do
    require_relative "rake"
  end
end if defined?(Rails)
