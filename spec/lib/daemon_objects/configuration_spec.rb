require 'spec_helper'

describe DaemonObjects::Configuration do
  describe '#handle_error' do
    it 'does nothing when no error handler configured' do
      expect(DaemonObjects.config.handle_error(StandardError.new)).to be_nil
    end

    it 'calls the configured error handler when configured' do
      msg = nil

      DaemonObjects.configure do |c|
        c.error_handler = Proc.new{|e| msg = e.message }
      end
      DaemonObjects.config.handle_error(StandardError.new("test"))

      expect(msg).to eq("test")
    end
  end
end
