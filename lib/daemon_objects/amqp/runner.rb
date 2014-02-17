module DaemonObjects::AmqpSupport
  attr_accessor :endpoint, :queue, :prefetch, :worker_class,
    :retry_wait_time

  def arguments
    @arguments ||= {}
  end

  def retry_wait_time
    @retry_wait_time || 5
  end

  def run
    logger.info "Preparing to start the AMQP watcher."

    connection = Bunny.new(endpoint) 
    connection.start

    logger.info "Starting up the AMQP watcher."

    channel  = connection.create_channel
    channel.prefetch(1) if prefetch

    worker   = worker_class.new(
      channel, 
      get_consumer, 
      {
        :queue_name => queue,
        :logger     => logger,
        :arguments  => arguments
      })
    worker.start

    logger.info "AMQP worker started"

    Signal.trap("INT") do
      logger.info "Received signal 'INT'.  Exiting process"
      connection.close { EventMachine.stop } 
    end

  rescue Bunny::InternalError, Bunny::TCPConnectionFailed => e
    logger.error(e) && e.backtrace.join("\n")
    wait && retry
  end

  def wait
    sleep(retry_wait_time)
    logger.info("*" * 20)
    logger.info("Retrying connection ....")
    logger.info("*" * 20)
  end
end
