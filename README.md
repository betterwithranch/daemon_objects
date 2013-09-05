# DaemonObjects
[![Build Status](https://travis-ci.org/craigisrael/daemon_objects.png)](https://travis-ci.org/craigisrael/daemon_objects)
[![Code Climate](https://codeclimate.com/github/craigisrael/daemon_objects.png)](https://codeclimate.com/github/craigisrael/daemon_objects)

Daemon Objects is designed to simplify using daemons in your ruby applications.  Under the hood, it uses the
[daemons](http://daemons.rubyforge.org) gem, which is a mature and tested solution.  But, it adds support for managing via rake tasks,
error handling and instrumentation.  

The [daemons](http://daemons.rubyforge.org) gem also is intended to be used to daemonize a ruby script.  DaemonObjects provides an 
object-oriented framework for developing daemons.  This allows the application developer to focus on the specific behavior of the daemon 
instead of the infrastructure of daemon management.

## Installation

Add this line to your application's Gemfile:

    gem 'daemon_objects'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install daemon_objects

## Usage

DaemonObjects will create daemons based on a simple convention.  It will search a directory for files name \*Daemon.rb.  These typically 
will just inherit from the base Daemon class.

    class MyDaemon < DaemonObjects::Base; end

This provides the basic daemon control methods (start, stop, run and restart) to your daemon.

To add behavior to your daemon, you will need a consumer.  DaemonObjects will load the consumer using the name of the daemon and
will search in the same directory for it.  For example, if your daemon is name MyDaemon, the consumer should be named MyConsumer.

A consumer needs to inherit from the consumer base and implement run.  For example, 

    class MyConsumer < DaemonObjects::ConsumerBase

      def run
        loop do
          "I'm looping"
          sleep 5
        end
      end

    end

### Rake tasks

Once you have defined the daemon, you can control it with rake tasks. To access the rake tasks,
you will need to include the daemon\_objects railtie in config/application.rb.

    require 'daemon_objects/railtie'

Rake tasks are created using the daemon file name.  The rake syntax is:

    rake daemon:<daemon_file_name>:<command>

For example, to start the MyDaemon daemon:

    rake daemon:my_daemon:start

Four commands are supported

* start   - Starts the daemon
* stop    - Stops the daemon
* restart - Stops and then starts the daemon
* run     - Runs the daemon synchronously

### Amqp Support

_in beta_

DaemonObjects also has support for monitoring an amqp queue.  This is done with the amqp gem.  To support this
with your daemon, add `supports_amqp` to your daemon class.

    class MyQueueProcessingDaemon < Daemon::Base
      supports_amqp :endpoint     => "http://localhost:5672",
                    :queue_name   => "my_awesome_queue",
                    :worker_class => MyAmqpWorker
    end

This will add the code to monitor the queue, so all you need now is code to handle the messages.

    class MyQueueProcessingConsumer < Daemon::ConsumerBase

      handle_messages_with do |payload|
        puts "payload"
      end

    end

### Logging

DaemonObjects will create a new log file for your daemon using the pattern _daemon\_file\_name_\_daemon.log.  In a rails project,
this will be created in the log directory of your application.

### Support for third-party libraries

DaemonObjects supports the following third-party libraries.  If they are required in your application, your daemon will use them.

* [Airbrake](http://airbrake.io) - any errors that occur in the daemon will be reported to Airbrake.
* [NewRelic](http://newrelic.com) - amqp daemons will have instrument the handle\_message method and report to New Relic.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
