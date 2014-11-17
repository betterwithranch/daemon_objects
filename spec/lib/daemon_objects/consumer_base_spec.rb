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

      h.payloads_received.should == [{:x => 1}]
    end
  end

  describe '#initialize' do
    let(:logger) { MemoryLogger::Logger.new }
    let(:harness) { Class.new(DaemonObjects::ConsumerBase) }

    it 'should set logger' do
      h = harness.new(:logger => logger)
      h.logger.should == logger
    end

    it 'should set app_directory' do
      h = harness.new(:app_directory => 'app_dir')
      h.app_directory.should == 'app_dir'
    end

    it 'should set environment' do
      h = harness.new(:environment => 'environment')
      h.environment.should == 'environment'
    end
  end

    
end
