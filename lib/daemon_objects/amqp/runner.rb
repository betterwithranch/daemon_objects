module DaemonObjects::AmqpSupport
  attr_accessor :endpoint, :queue, :prefetch, :worker_class

  def arguments
    @arguments ||= {}
  end

  def run
    logger.info "Preparing to start the AMQP watcher."

    connection = Bunny.new("#{endpoint.gsub("/", "%2F")}") 
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
  end
end
