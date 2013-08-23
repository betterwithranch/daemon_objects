require "daemon_objects/version"
require 'active_support/core_ext/string'
require 'daemons'
require 'amqp'
require 'logger'

module DaemonObjects; end

require 'daemon_objects/loader'
require 'daemon_objects/base'
require 'daemon_objects/consumer_base'
require 'daemon_objects/amqp_support'
require 'daemon_objects/railtie'

