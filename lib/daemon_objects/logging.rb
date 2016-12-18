module DaemonObjects::Logging

  def log_filename
    "#{to_s.underscore}.log"
  end

  def log_directory
    File.join(app_directory, "log")
  end

  def logger
    @logger ||= create_logger
  end

  def create_logger
    FileUtils.mkdir_p log_directory
    logger = ::Logger.new(File.open(File.join(log_directory, log_filename), "a"))
    logger.formatter = ::Logger::Formatter.new
    logger
  end

  def logger=(value)
    @logger = value
  end

  def force_logger_reset
    @logger = nil
    Rails.logger = logger if defined?(Rails)
  end

end
