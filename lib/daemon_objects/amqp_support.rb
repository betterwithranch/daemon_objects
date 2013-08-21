module DaemonObjects::AmqpSupport
  attr_accessor :endpoint, :queue, :prefetch

  def arguments
    @arguments ||= {}
  end

  def run
    logger.info "Preparing to start the AMQP watcher."
    AMQP.start(endpoint) do |connection, open_ok|
      logger.info "Starting up the AMQP watcher."

      channel  = AMQP::Channel.new(connection)
      channel.prefetch(1) if prefetch

      worker   = OnlifeMessaging::Worker.new(
        channel, 
        get_consumer, 
        {
          :queue_name => queue,
          :arguments  => arguments
        })

      worker.start

      Signal.trap("INT") do
        logger.info "Exiting process"
        connection.close { EventMachine.stop } 
      end


    end
  end
end
