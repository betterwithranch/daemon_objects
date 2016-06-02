require 'spec_helper'

describe DaemonObjects::Amqp::Worker do

  let(:consumer) { ErrorGeneratingConsumer.new }
  let(:channel)  { BunnyMock.new.create_channel }
  let(:logger)   { MemoryLogger::Logger.new }

  describe '#handle_message' do
    context 'error raised by consumer' do
      let(:worker)   { DaemonObjects::Amqp::Worker.new(channel, consumer, logger: logger) }

      it 'does not acknowledge' do
        expect(channel).not_to receive(:acknowledge)
        worker.handle_message(channel, 1, "{}")
      end

      it 'it rejects the message' do
        expect(channel).to receive(:reject)
        worker.handle_message(channel, 1, "{}")
      end
    end

  end
end
