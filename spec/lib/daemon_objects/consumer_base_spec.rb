require 'spec_helper'

describe DaemonObjects::ConsumerBase do
  describe '#handle_message' do
    it 'should call the configured message handler' do

      Harness = Class.new(DaemonObjects::ConsumerBase) do
        def payloads_received
          @payloads_received ||= []
        end

        handle_messages_with{|p| payloads_received << p }
      end

      h = Harness.new(StubLogger.new)
      h.handle_message({:x => 1})

      h.payloads_received.should == [{:x => 1}]
    end
  end
    
end
