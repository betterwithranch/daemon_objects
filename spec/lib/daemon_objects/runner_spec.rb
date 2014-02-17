require 'spec_helper'

describe DaemonObjects::AmqpSupport do
  before :each do
    MyWorker = Class.new(DaemonObjects::Amqp::Worker) do
      def initialize(*args); end
      def start; end
      def self.counter
        @counter ||= 0
      end

      def self.counter=(value)
        @counter = value
      end
    end

    MyConsumer = Class.new(DaemonObjects::ConsumerBase)
    MyDaemon = Class.new(DaemonObjects::Base) do
      consumes_amqp :endpoint        => 'amqp://localhost:4567',
                    :queue_name      => 'queue',
                    :worker_class    => MyWorker,
                    :retry_wait_time => 0
    end
  end

  after :each do
    Object.send( :remove_const, :MyWorker) if defined?(MyWorker)
    Object.send( :remove_const, :MyConsumer) if defined?(MyConsumer)
    Object.send( :remove_const, :MyDaemon) if defined?(MyDaemon)
  end

  it 'should retry on initial connection if cannot connect' do

    bunny = double(Bunny).as_null_object
    # First attempt should raise and retry
    Bunny.should_receive(:new).
      with('amqp://localhost:4567'){
        raise Bunny::TCPConnectionFailed.new("could not connect", "localhost", 4567)
      }

    # Second attempt succeeds to exit spec
    Bunny.should_receive(:new).
      with('amqp://localhost:4567').and_return(bunny)
    MyDaemon.run
  end

  it 'should retry if connection is lost' do
    bunny = double(Bunny).as_null_object

    MyWorker.class_eval do
      def start
        self.class.counter += 1
        # Only raise error on first attempt
        raise Bunny::InternalError.new('lost connection', nil, true) if self.class.counter <= 1
      end
    end

    Bunny.should_receive(:new).twice.
      with('amqp://localhost:4567').and_return(bunny)

    MyDaemon.run
  end
end
