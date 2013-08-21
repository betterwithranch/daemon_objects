require "daemon_objects/version"

module DaemonObjects; end

["base", "consumer_base", "amqp_support"].each do |file|
  require File.join(File.dirname(__FILE__), "daemon_objects", "#{file}.rb")
end

