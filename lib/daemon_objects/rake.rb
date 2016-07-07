require 'loader' unless Object.const_defined?(:DaemonObjects)

namespace :daemon do

  # create tasks for each daemon to start/stop/restart/run
  DaemonObjects.daemons.each do |daemon|

    namespace daemon do
      description = "#{daemon.to_s.gsub("_", " ")} daemon"
      desc "starts the #{description}; can substitute stop or restart for start, " +
        "or use run to run the daemon in the foreground"


      task :daemon_environment do
        Rake::Task[:environment].invoke if Rake::Task.task_defined?(:environment)
        DaemonObjects.initialize_environment
      end

      [:start, :stop, :run].each do |action|
        task action => [:daemon_environment]  do
          require "daemon_objects"
          require "#{DaemonObjects.daemon_path}/#{daemon}_daemon.rb"
          require "#{DaemonObjects.daemon_path}/#{daemon}_consumer.rb"

          puts "#{description} #{action}"
          daemon_class = "#{daemon}_daemon".camelcase.constantize
          daemon_class.send(action)
        end
      end

      task :restart => [:stop, :start]
    end
  end

  namespace :all do

    desc 'start all daemons'
    task :start => DaemonObjects.daemons.map{|d| "daemon:#{d}:start"}

    desc 'stop all daemons'
    task :stop => DaemonObjects.daemons.map{|d| "daemon:#{d}:stop"}

    desc 'restart all daemons'
    task :restart => [:stop, :start]
  end

  task :list do
    DaemonObjects.daemons.each {|d| puts d }
  end

end
