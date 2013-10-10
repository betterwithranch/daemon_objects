class DaemonObjects::Amqp::Worker
  attr_accessor :queue_name, :exchange, :routing_key, :channel, :consumer, :arguments, :logger

  DEFAULTS = {
    :queue_name  => AMQ::Protocol::EMPTY_STRING,
    :exchange    => nil,
    :routing_key => AMQ::Protocol::EMPTY_STRING,
    :arguments   => nil
  }

  def initialize(channel, consumer, options={})
    self.consumer = consumer
    self.channel  = channel

    parse_options(DEFAULTS.merge(options))
  end

  def parse_options(options)
    options.each do |k,v|
      self.send("#{k}=", v) if self.respond_to?("#{k}=")
    end
  end

  def channel=(value)
    value.on_error(&method(:handle_channel_exception))
    @channel = value
  end

  def start
    queue = channel.queue(queue_name, :durable => true, :ack => true, :arguments => arguments)
    queue.bind(exchange, :routing_key => routing_key) if exchange

    queue.subscribe(:ack => true) do |metadata, payload|
      exception = handle_message(metadata, payload)

      response_payload = consumer.get_response(payload, exception) if consumer.respond_to?(:get_response)
      if response_payload
        channel.default_exchange.publish(response_payload.to_json, 
                                         :routing_key    => metadata.reply_to, 
                                         :correlation_id => metadata.message_id)
      end
    end
  end

  def handle_channel_exception(channel, channel_close)
    raise StandardError, "ERROR channel-level exception: code = #{channel_close.reply_code}, message = #{channel_close.reply_text}"
  end

  def handle_message(metadata, payload)
    consumer.handle_message (payload)
    metadata.ack
  rescue Exception => e
    metadata.reject
    logger.error "Error occurred handling message, the payload was: #{payload}, the error was: '#{e}'."
  end
end
