namespace :daemon do

  # create tasks for each daemon to start/stop/restart/run
  DaemonObjects.daemons.each do |daemon|

    namespace daemon do
      description = "#{daemon.to_s.gsub("_", " ")} daemon"
      desc "starts the #{description}; can substitute stop or restart for start, " +
        "or use run to run the daemon in the foreground"

      [:start, :stop, :run].each do |action|
        task action => :environment do

          require "daemon_objects"
          require "#{DaemonObjects.daemon_path}/#{daemon}_daemon.rb"
          require "#{DaemonObjects.daemon_path}/#{daemon}_consumer.rb"


          puts "#{description} #{action}"
          daemon_class = "#{daemon}_daemon".camelcase.constantize
          daemon_class.send(action)
        end
      end

      task :restart => [:environment, :stop, :start]
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

end
