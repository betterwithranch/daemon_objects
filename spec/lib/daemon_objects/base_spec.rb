require 'spec_helper'

describe DaemonObjects::Base do
  after :each do
    Object.instance_eval{ remove_const(:MyDaemon)} if defined?(MyDaemon)
    Object.instance_eval{ remove_const(:ThreePartNameDaemon)} if defined?(ThreePartNameDaemon)
    Object.instance_eval{ remove_const(:MyConsumer)} if defined?(MyConsumer)
  end

  describe '#run' do
    it 'should create new consumer' do
      MyConsumer = Class.new(DaemonObjects::ConsumerBase)

      MyDaemon = Class.new(DaemonObjects::Base) do
        self.logger = StubLogger.new
      end

      MyDaemon.run
      MyDaemon.logger.logged_output.should =~ /Starting consumer\n/
    end

  end

  describe '#start' do
    it 'should call daemon run_proc' do
      MyDaemon = Class.new(DaemonObjects::Base)
      Daemons.should_receive(:run_proc).
        with(MyDaemon.proc_name,
             { :ARGV       => ['start', '-f'],
               :log_dir    => "/tmp",
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
             { :ARGV => ['stop', '-f'] })
      MyDaemon.stop
    end
  end

  describe '##logger' do
    it 'should create a logger at log/log_filename path' do
      MyDaemon = Class.new(DaemonObjects::Base)
      logger = StubLogger.new

      Logger.stub(:new).
        with("#{MyDaemon.log_directory}/#{MyDaemon.log_filename}").
        and_return(logger)

      MyDaemon.logger.info("starting consumer")

      logger.logged_output.should =~ /starting consumer\n$/
    end
  end

  describe '#create_logger' do
    it 'should create a logger with timestamp formatting' do
      MyDaemon = Class.new(DaemonObjects::Base)
      logger = MyDaemon.logger
      logger.formatter.class.should == ::Logger::Formatter
    end
  end

#  describe '#log_path' do
#    it 'should use Rails log path when Rails is defined' do
#        MyDaemon = Class.new(DaemonObjects::Base)
#        MyDaemon.log_directory.to_s.should == File.join(Rails.root, "log")
#    end
#  end

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

  describe 'AMQP support' do
    let(:endpoint){ }

    before :each do
      MyWorker = Class.new do
        def initialize(*args); end
        def run; end
      end
    end

    after :each do
      Object.instance_eval{ remove_const(:MyWorker)} if defined?(MyWorker)
    end

    it 'should start AMQP if daemon is an amqp consumer' do
      MyConsumer = Class.new(DaemonObjects::ConsumerBase)
      MyDaemon = Class.new(DaemonObjects::Base) do
        consumes_amqp :endpoint   => 'amqp://localhost:4567',
                      :queue_name => 'queue',
                      :worker_class => MyWorker
      end

      AMQP.should_receive(:start).with('amqp://localhost:4567').and_return(true)
      MyDaemon.run
    end

    it 'should not start AMQP if daemon is not an amqp consumer' do
      MyConsumer = Class.new(DaemonObjects::ConsumerBase)
      MyDaemon = Class.new(DaemonObjects::Base)

      AMQP.should_not_receive(:start)
      MyDaemon.run

    end

    it 'should start a worker' do
      MyConsumer = Class.new(DaemonObjects::ConsumerBase)
      MyDaemon = Class.new(DaemonObjects::Base) do
        consumes_amqp :endpoint   => 'amqp://localhost:4567',
                      :queue_name => 'queue',
                      :worker_class => MyWorker
      end

      def AMQP.start(endpoint)
        yield "connection", "open"
      end

      channel = double(AMQP::Channel)
      AMQP::Channel.stub(:new).and_return(channel)
      channel.should_not_receive(:prefetch)

      worker  = MyWorker.new
      consumer = MyDaemon.get_consumer
      MyDaemon.stub(:get_consumer).and_return(consumer)

      MyWorker.should_receive(:new).
        with(channel, consumer, {
              :queue_name => 'queue',
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

      def AMQP.start(endpoint)
        yield "connection", "open"
      end

      channel = double(AMQP::Channel)
      channel.should_receive(:prefetch).with(1)

      AMQP::Channel.stub(:new).and_return(channel)

      worker  = MyWorker.new
      consumer = MyDaemon.get_consumer
      MyDaemon.stub(:get_consumer).and_return(consumer)

      MyWorker.should_receive(:new).
        with(channel, consumer, {
              :queue_name => 'queue',
              :arguments  => {}
        }).
        and_return(worker)
      worker.should_receive(:start)

      MyDaemon.run
    end
  end

end


