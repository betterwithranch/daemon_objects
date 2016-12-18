require 'spec_helper'

describe DaemonObjects::ConsumerBase do
  describe '#handle_message' do
    after :each do
      Object.send(:remove_const, :Harness)
    end

    it 'should call the configured message handler' do

      Harness = Class.new(DaemonObjects::ConsumerBase) do
        def payloads_received
          @payloads_received ||= []
        end

        handle_messages_with{|p| payloads_received << p }
      end

      h = Harness.new(:logger => MemoryLogger::Logger.new)
      h.handle_message({:x => 1})

      expect(h.payloads_received).to eq([{:x => 1}])
    end

    it 'calls the configured error handler on error' do
      err = StandardError.new("test message")
      Harness = Class.new(DaemonObjects::ConsumerBase) do
        handle_messages_with{|p| raise err }
      end

      expect(DaemonObjects.config).to receive(:handle_error).with(err)
      h = Harness.new(:logger => MemoryLogger::Logger.new)
      h.handle_message({x: 1})
    end
  end

  describe '#initialize' do
    let(:logger) { MemoryLogger::Logger.new }
    let(:harness) { Class.new(DaemonObjects::ConsumerBase) }

    it 'should set logger' do
      h = harness.new(:logger => logger)
      expect(h.logger).to eq(logger)
    end

    it 'should set app_directory' do
      h = harness.new(:app_directory => 'app_dir')
      expect(h.app_directory).to eq('app_dir')
    end

    it 'should set environment' do
      h = harness.new(:environment => 'environment')
      expect(h.environment).to eq('environment')
    end
  end

    
end
