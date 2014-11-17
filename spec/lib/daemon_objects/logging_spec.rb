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
      logger = StubLogger.new

      Logger.stub(:new).
        with("#{harness.log_directory}/#{harness.log_filename}").
        and_return(logger)

      harness.logger.info("starting consumer")

      logger.logged_output.should =~ /starting consumer\n$/
    end
  end

  describe '#create_logger' do
    it 'should create a logger with timestamp formatting' do
      logger = harness.logger
      logger.formatter.class.should == ::Logger::Formatter
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
      MyDaemon.log_filename.should == "my_daemon.log"
    end
  end

  describe '#log_directory' do
    it "should use 'log' for default log path" do
      harness.log_directory.to_s.should == File.join(harness.app_directory, "log")
    end
  end


end
