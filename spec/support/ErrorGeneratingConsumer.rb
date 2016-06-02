class ErrorGeneratingConsumer < DaemonObjects::ConsumerBase

  def initialize
    super logger: MemoryLogger::Logger.new
  end

  handle_messages_with do |payload|
    raise StandardError, "generated error"
  end
end
