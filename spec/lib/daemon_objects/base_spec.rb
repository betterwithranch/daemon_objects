require 'spec_helper'

describe DaemonObjects::Base do
  after :each do
    [ :MyDaemon, :MyTestDaemon, :ThreePartNameDaemon, :MyConsumer].each do |sym|
      Object.send(:remove_const, sym) if Object.const_defined?(sym)
    end
  end

  describe '##description' do
    it 'sets the description for the daemon' do
      MyDaemon = Class.new(DaemonObjects::Base) do
        self.description = "My daemon description"
      end

      expect(MyDaemon.description).to eq("My daemon description")
    end

  end
  describe '#app_directory' do
    it 'should be Rake.original_directory if Rails is not defined' do
      allow(Rake).to receive(:original_dir).and_return("/mydir")
      MyDaemon = Class.new(DaemonObjects::Base)
      expect(MyDaemon.app_directory).to eq(Rake.original_dir)
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
        expect(MyDaemon.app_directory).to eq(Rails.root)
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

  describe '#extends' do
    it 'should extend logging' do
      MyDaemon = Class.new(DaemonObjects::Base)
      expect(MyDaemon.singleton_class.included_modules).to include(DaemonObjects::Logging)
    end
  end

  describe '#run' do
    it 'should create new consumer' do
      MyConsumer = Class.new(DaemonObjects::ConsumerBase)

      MyDaemon = Class.new(DaemonObjects::Base) do
        self.logger = MemoryLogger::Logger.new
      end

      MyDaemon.run
      expect(MyDaemon.logger.logged_output).to match(/Starting consumer/)
    end

  end

  describe '#start' do
    it 'should call daemon run_proc' do
      MyDaemon = Class.new(DaemonObjects::Base)
      expect(Daemons).to receive(:run_proc).
        with(MyDaemon.proc_name,
             { :ARGV       => ['start', '-f'],
               :log_dir    => "/tmp",
               :dir        => MyDaemon.pid_directory,
               :log_output => true,
               :multiple   => true
              } )
      MyDaemon.start
    end
  end

  describe '#stop' do
    it 'should call daemon stop_proc' do
      MyDaemon = Class.new(DaemonObjects::Base)
      expect(Daemons).to receive(:run_proc).
        with(MyDaemon.proc_name,
             { :ARGV => ['stop', '-f'],
              :dir   => MyDaemon.pid_directory})
      MyDaemon.stop
    end
  end

  describe '#instances' do
    let(:daemon) { MyTestDaemon = Class.new(DaemonObjects::Base) }

    before :each do
      allow(daemon).to receive(:app_directory).and_return("spec/fixtures")
    end

    it 'defaults to 1' do
      expect(daemon.instances).to eq(1)
    end

    it 'matches the file value when found' do
      allow(daemon).to receive(:config_file_name).and_return("with_count.yml")
      expect(daemon.instances).to eq(4)
    end

    it 'is 1 when file does not match env' do
      allow(daemon).to receive(:config_file_name).and_return("no_env.yml")
      expect(daemon.instances).to eq(1)
    end

    it 'is 1 when file matches env, but not daemon' do
      allow(daemon).to receive(:config_file_name).and_return("no_daemon.yml")
      expect(daemon.instances).to eq(1)
    end
  end

  describe '##consumer_class' do
    it 'should constantize a file with multiple part name' do
      ThreePartNameConsumer = Class.new
      ThreePartNameDaemon = Class.new(DaemonObjects::Base)
      expect(ThreePartNameDaemon.consumer_class).to eq(ThreePartNameConsumer)
    end
  end

  describe '##proc_name' do
    it 'should underscore class to get daemon name' do
      ThreePartNameDaemon = Class.new(DaemonObjects::Base)
      expect(ThreePartNameDaemon.proc_name).to eq("three_part_name_daemon")
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
        self.logger = MemoryLogger::Logger.new
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
      DaemonObjects.environment = "theenv"
      expect(consumer.environment).to eq("theenv")
    end

    it 'should set app directory' do
      def MyDaemon.app_directory
        "thedir"
      end

      expect(consumer.app_directory).to eq("thedir")
    end

    it 'should set logger' do
      logger = MemoryLogger::Logger.new
      allow(MyDaemon).to receive(:logger).and_return(logger)

      expect(consumer.logger).to eq(logger)
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
      expect(Bunny).to receive(:new).with('amqp://localhost:4567').and_return(bunny)
      MyDaemon.run
    end

    it 'should not start AMQP if daemon is not an amqp consumer' do
      MyConsumer = Class.new(DaemonObjects::ConsumerBase)
      MyDaemon = Class.new(DaemonObjects::Base)

      expect(Bunny).not_to receive(:new)
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
      allow(Bunny).to receive(:new).and_return(bunny)
      channel = double(Bunny::Channel)
      allow(bunny).to receive(:create_channel).and_return(channel)
      expect(channel).not_to receive(:prefetch)

      worker  = MyWorker.new
      consumer = MyDaemon.get_consumer
      allow(MyDaemon).to receive(:get_consumer).and_return(consumer)

      expect(MyWorker).to receive(:new).
        with(channel, consumer, {
              :queue_name => 'queue',
              :logger     => MyDaemon.logger,
              :arguments  => {}
        }).
        and_return(worker)
      expect(worker).to receive(:start)

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
      allow(Bunny).to receive(:new).and_return(bunny)
      channel = double(Bunny::Channel)
      expect(channel).to receive(:prefetch).with(1)

      allow(bunny).to receive(:create_channel).and_return(channel)

      worker  = MyWorker.new
      consumer = MyDaemon.get_consumer
      allow(MyDaemon).to receive(:get_consumer).and_return(consumer)

      expect(MyWorker).to receive(:new).
        with(channel, consumer, {
              :queue_name => 'queue',
              :logger     => MyDaemon.logger,
              :arguments  => {}
        }).
        and_return(worker)
      expect(worker).to receive(:start)

      MyDaemon.run
    end
  end

  describe '#handle_error' do
    it 'calls the configured error handler' do
      MyDaemon = Class.new(DaemonObjects::Base)
      err = StandardError.new("test message")
      err.set_backtrace(caller)

      expect(DaemonObjects.config).to receive(:handle_error).with(err)
      MyDaemon.handle_error(err)
    end
  end

end
