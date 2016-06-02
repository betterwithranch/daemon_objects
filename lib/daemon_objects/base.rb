require 'daemon_objects/logging'

class DaemonObjects::Base
  extend DaemonObjects::Logging

  def self.consumes_amqp(opts={})
    extend DaemonObjects::Amqp::Runner
    self.endpoint                   = opts.delete(:endpoint)
    self.queue                      = opts.delete(:queue_name)
    self.arguments["x-message-ttl"] = opts.delete(:ttl) if opts[:ttl]
    self.prefetch                   = opts.delete(:prefetch)
    self.retry_wait_time            = opts.delete(:retry_wait_time)
    self.worker_class               = opts.delete(:worker_class) || DaemonObjects::Amqp::Worker
    self.arguments.merge!(opts)

    logger.info "Configured to consume queue [#{queue}] at endpoint [#{endpoint}]"
    logger.info "Worker class is '#{worker_class}'"
  end

  def self.app_directory
    @app_directory ||= (defined? Rails) ? Rails.root : Rake.original_dir
  end

  def self.pid_directory
    File.join(app_directory, "tmp/pids")
  end

  def self.consumer_class
    @consumer_class ||= "#{self.to_s.gsub("Daemon", "")}Consumer".constantize
  end

  def self.proc_name
    @proc_name ||= self.to_s.underscore
  end

  def self.get_consumer
    consumer_class.new(:logger        => logger,
                       :app_directory => app_directory,
                       :environment   => DaemonObjects.environment)
  end

  def self.run
    begin
      get_consumer.run
    rescue StandardError => e
      handle_error(e)
    end
  end

  def self.after_fork
    # daemonizing closes all file handles, so this will reopen the log
    force_logger_reset
    # this seems to be enough to initialize NewRelic if it's defined
    defined?(NewRelic)
  end

  def self.start
    # connection will get severed on fork, so disconnect first
    ActiveRecord::Base.connection.disconnect! if defined?(ActiveRecord::Base)

    FileUtils.mkdir_p(pid_directory)

    Daemons.run_proc(proc_name,
                    { :ARGV       => ["start", "-f"],
                      :log_dir    => "/tmp",
                      :dir        => pid_directory,
                      :log_output => true}) do

      after_fork
      run
    end

  rescue StandardError => e
    handle_error(e)
  end

  def self.stop
    Daemons.run_proc(proc_name, { :ARGV => [ "stop", "-f" ], :dir => pid_directory})
  end

  def self.restart
    start
    stop
  end

  def self.handle_error(e)
    logger.error(e.message)
    logger.error(e.backtrace.join("\n"))
    Airbrake.notify(e) if defined?(Airbrake)
  end
end
