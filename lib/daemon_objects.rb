require "daemon_objects/version"

module DaemonObjects; end

require 'active_support/core_ext/string'
require 'daemons'
require 'amqp'
require 'logger'

["base", "consumer_base", "amqp_support"].each do |file|
  require File.join(File.dirname(__FILE__), "daemon_objects", "#{file}.rb")
end

