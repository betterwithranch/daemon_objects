require 'spec_helper'

describe DaemonObjects::Base do
  after :each do
    [ :MyDaemon, :ThreePartNameDaemon, :MyConsumer].each do |sym|
      Object.send(:remove_const, sym) if Object.const_defined?(sym)
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


