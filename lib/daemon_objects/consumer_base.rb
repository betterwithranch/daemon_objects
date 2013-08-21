class DaemonObjects::ConsumerBase

  include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation if defined?(::NewRelic)

  class << self 
    attr_accessor :message_handler
  end

  attr_accessor :logger

  def initialize(logger)
    @logger = logger
  end

  def run
    logger.info("Starting consumer")
  end

  def handle_message(payload)
    logger.info("Handling message #{payload}")
    handle_message_impl(payload)
    logger.info("Completed handling message")
  rescue StandardError => e
    logger.error("#{e.class}:  #{e.message}")
    logger.error(e.backtrace.join("\n"))
  end

  def self.handle_messages_with(&block)
    raise StandardError.new("Provided block must take at least one argument - 'payload'") if block.arity < 1
    define_method(:handle_message_impl, &block) 
  end

  add_transaction_tracer :handle_message, :category => :task if defined?(::NewRelic)
end
