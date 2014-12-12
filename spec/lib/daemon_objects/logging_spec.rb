require 'spec_helper'

describe DaemonObjects::Logging do
  let(:harness) do
    Class.new do
      extend DaemonObjects::Logging

      def self.app_directory
        "."
      end
    end
  end

  describe '#logger' do
    it 'should create a logger at log/log_filename path' do
      logger = MemoryLogger::Logger.new

      allow(Logger).to receive(:new).
        with("#{harness.log_directory}/#{harness.log_filename}").
        and_return(logger)

      harness.logger.info("starting consumer")

      expect(logger.logged_output).to match(/starting consumer/)
    end
  end

  describe '#create_logger' do
    it 'should create a logger with timestamp formatting' do
      logger = harness.logger
      expect(logger.formatter.class).to eq(::Logger::Formatter)
    end
  end

  describe '#log_filename' do
    before :each do
      MyDaemon = Class.new do
        extend DaemonObjects::Logging
      end
    end

    after :each do
      Object.send(:remove_const, :MyDaemon)
    end

    it 'should underscore name for log file' do
      expect(MyDaemon.log_filename).to eq("my_daemon.log")
    end
  end

  describe '#log_directory' do
    it "should use 'log' for default log path" do
      expect(harness.log_directory.to_s).to eq(File.join(harness.app_directory, "log"))
    end
  end


end
