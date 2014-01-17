require "daemon_objects/version"
require 'active_support/core_ext/string'
require 'daemons'
require 'logger'
require 'bunny'

module DaemonObjects; end

require 'daemon_objects/loader'
require 'daemon_objects/amqp'
require 'daemon_objects/base'
require 'daemon_objects/consumer_base'
require 'daemon_objects/railtie'

