require "daemon_objects/version"
require 'active_support/core_ext/string'
require 'yaml'
require 'daemons'
require 'logger'
require 'bunny'
require 'daemon_objects/configuration'

module DaemonObjects
  class << self
    attr_accessor :environment

    def initialize_environment
      @environment = (defined? Rails) ? Rails.env : (ENV["DAEMON_ENV"] || "development")
    end

    def configure
      yield config
    end

    def config
      @config ||= DaemonObjects::Configuration.new
    end
  end
end

require 'daemon_objects/loader'
require 'daemon_objects/amqp'
require 'daemon_objects/base'
require 'daemon_objects/consumer_base'
require 'daemon_objects/railtie'

