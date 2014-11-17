require 'spec_helper'

describe DaemonObjects::Base do
  after :each do
    [ :MyDaemon, :ThreePartNameDaemon, :MyConsumer].each do |sym|
      Object.send(:remove_const, sym) if Object.const_defined?(sym)
    end
  end

  describe '#app_directory' do
    it 'should be Rake.original_directory if Rails is not defined' do
      Rake.stub(:original_dir).and_return("/mydir")
      MyDaemon = Class.new(DaemonObjects::Base)
      MyDaemon.app_directory.should == Rake.original_dir
    end

    context 'Rails' do
      before :each do
        Rails = Module.new do
          def self.root
            "/mydir"
          end
        end
      end

      after :each do
        Object.send(:remove_const, :Rails)
      end

      it 'should be Rails.root is Rails is defined' do
        MyDaemon = Class.new(DaemonObjects::Base)
        MyDaemon.app_directory.should == Rails.root
      end
    end

    it 'should allow app_directory to be set explicitly' do
      MyDaemon = Class.new(DaemonObjects::Base) do
        def app_directory
          "."
        end
      end
    end
  end

  describe '#environment' do
    context 'Rails' do
      before :each do
        Rails = Module.new do
          def self.env
            "railsenv"
          end
        end
      end

      after :each do
        Object.send(:remove_const, :Rails)
      end

      it 'should use Rails.env if Rails is defined' do
        MyDaemon = Class.new(DaemonObjects::Base)
        MyDaemon.environment.should == Rails.env
      end
    end

    context 'Env variable set' do
      before :each do
        ENV["DAEMON_ENV"] = "daemonenv"
      end
      after :each do
        ENV["DAEMON_ENV"] = nil
      end
      it 'should use environment variable if Rails is not defined' do
        MyDaemon = Class.new(DaemonObjects::Base)
        MyDaemon.environment.should == ENV["DAEMON_ENV"]
      end
    end

    it 'should be nil if not Rails and no environment set' do
      MyDaemon = Class.new(DaemonObjects::Base)
      MyDaemon.environment.should be_nil
    end
  end

  describe '#extends' do
    it 'should extend logging' do
      MyDaemon = Class.new(DaemonObjects::Base)
      MyDaemon.singleton_class.included_modules.should include(DaemonObjects::Logging)
    end
  end

  describe '#run' do
    it 'should create new consumer' do
      MyConsumer = Class.new(DaemonObjects::ConsumerBase)

      MyDaemon = Class.new(DaemonObjects::Base) do
        self.logger = MemoryLogger::Logger.new
      end

      MyDaemon.run
      MyDaemon.logger.logged_output.should =~ /Starting consumer/
    end

  end

  describe '#start' do
    it 'should call daemon run_proc' do
      MyDaemon = Class.new(DaemonObjects::Base)
      Daemons.should_receive(:run_proc).
        with(MyDaemon.proc_name,
             { :ARGV       => ['start', '-f'],
               :log_dir    => "/tmp",
               :dir        => MyDaemon.pid_directory,
               :log_output => true
              } )
      MyDaemon.start
    end
  end

  describe '#stop' do
    it 'should call daemon stop_proc' do
      MyDaemon = Class.new(DaemonObjects::Base)
      Daemons.should_receive(:run_proc).
        with(MyDaemon.proc_name,
             { :ARGV => ['stop', '-f'],
              :dir   => MyDaemon.pid_directory})
      MyDaemon.stop
    end
  end

  describe '##consumer_class' do
    it 'should constantize a file with multiple part name' do
      ThreePartNameConsumer = Class.new
      ThreePartNameDaemon = Class.new(DaemonObjects::Base)
      ThreePartNameDaemon.consumer_class.should == ThreePartNameConsumer
    end
  end

  describe '##proc_name' do
    it 'should underscore class to get daemon name' do
      ThreePartNameDaemon = Class.new(DaemonObjects::Base)
      ThreePartNameDaemon.proc_name.should == "three_part_name_daemon"
    end
  end

  describe '##get_consumer' do


    it 'should log exceptions during consumer instantiation' do
      TestConsumer = Class.new(DaemonObjects::ConsumerBase) do
        def initialize(logger)
          super
          raise StandardError.new("Test")
        end
      end
      TestDaemon = Class.new(DaemonObjects::Base) do
        self.logger = StubLogger.new
      end

      expect {TestDaemon.get_consumer}.to raise_error(StandardError)
      TestDaemon.logger.logged_output =~ /Message: Test/
    end

    let(:consumer) { MyDaemon.get_consumer }

    before :each do
      MyConsumer = Class.new(DaemonObjects::ConsumerBase)
      MyDaemon = Class.new(DaemonObjects::Base)
    end

    after :each do
      Object.send(:remove_const, :MyDaemon)
      Object.send(:remove_const, :MyConsumer)
    end

    it 'should set environment' do
      def MyDaemon.environment
        "theenv"
      end

      consumer.environment.should == "theenv"
    end

    it 'should set app directory' do
      def MyDaemon.app_directory
        "thedir"
      end

      consumer.app_directory.should == "thedir"
    end

    it 'should set logger' do
      logger = MemoryLogger::Logger.new
      MyDaemon.stub(:logger).and_return(logger)

      consumer.logger.should == logger
    end
  end

  describe 'AMQP support' do
    let(:endpoint){ }

    before :each do
      MyWorker = Class.new(DaemonObjects::Amqp::Worker) do
        def initialize(*args); end
        def start; end
      end
    end

    after :each do
      Object.send( :remove_const, :MyWorker) if defined?(MyWorker)
    end

    it 'should start AMQP if daemon is an amqp consumer' do
      MyConsumer = Class.new(DaemonObjects::ConsumerBase)
      MyDaemon = Class.new(DaemonObjects::Base) do
        consumes_amqp :endpoint   => 'amqp://localhost:4567',
                      :queue_name => 'queue',
                      :worker_class => MyWorker
      end

      bunny = double(Bunny).as_null_object
      Bunny.should_receive(:new).with('amqp://localhost:4567').and_return(bunny)
      MyDaemon.run
    end

    it 'should not start AMQP if daemon is not an amqp consumer' do
      MyConsumer = Class.new(DaemonObjects::ConsumerBase)
      MyDaemon = Class.new(DaemonObjects::Base)

      Bunny.should_not_receive(:new)
      MyDaemon.run

    end

    it 'should start a worker' do
      MyConsumer = Class.new(DaemonObjects::ConsumerBase)
      MyDaemon = Class.new(DaemonObjects::Base) do
        consumes_amqp :endpoint   => 'amqp://localhost:4567',
                      :queue_name => 'queue',
                      :worker_class => MyWorker
      end

      bunny = double(Bunny).as_null_object
      Bunny.stub(:new).and_return(bunny)
      channel = double(Bunny::Channel)
      bunny.stub(:create_channel).and_return(channel)
      channel.should_not_receive(:prefetch)

      worker  = MyWorker.new
      consumer = MyDaemon.get_consumer
      MyDaemon.stub(:get_consumer).and_return(consumer)

      MyWorker.should_receive(:new).
        with(channel, consumer, {
              :queue_name => 'queue',
              :logger     => MyDaemon.logger,
              :arguments  => {}
        }).
        and_return(worker)
      worker.should_receive(:start)

      MyDaemon.run
    end

    it 'should use prefetch value when available' do
      MyConsumer = Class.new(DaemonObjects::ConsumerBase)
      MyDaemon = Class.new(DaemonObjects::Base) do
        consumes_amqp :endpoint     => 'amqp://localhost:4567',
                      :queue_name   => 'queue',
                      :prefetch     => 1,
                      :worker_class => MyWorker
      end

      bunny = double(Bunny).as_null_object
      Bunny.stub(:new).and_return(bunny)
      channel = double(Bunny::Channel)
      channel.should_receive(:prefetch).with(1)

      bunny.stub(:create_channel).and_return(channel)

      worker  = MyWorker.new
      consumer = MyDaemon.get_consumer
      MyDaemon.stub(:get_consumer).and_return(consumer)

      MyWorker.should_receive(:new).
        with(channel, consumer, {
              :queue_name => 'queue',
              :logger     => MyDaemon.logger,
              :arguments  => {}
        }).
        and_return(worker)
      worker.should_receive(:start)

      MyDaemon.run
    end
  end

end


