require "daemon_objects/version"
require 'active_support/core_ext/string'
require 'daemons'
require 'amqp'
require 'logger'

module DaemonObjects 
  ROOT = File.join(File.dirname(__FILE__))

  DAEMON_FILE_ENDING = "_daemon.rb"

  class << self 
    attr_accessor :daemon_path

    def daemon_path
      @daemon_path ||= File.join(Rake.application.original_dir, "lib/daemons")
    end

    def daemons
      @daemons ||= get_daemons
    end

    def get_daemon_name(path)
      file = Pathname(path).basename.to_s
      file.gsub!(/#{DAEMON_FILE_ENDING}$/, "")
    end

    private
    
    def get_daemons
      paths = Dir["#{daemon_path}/*#{DAEMON_FILE_ENDING}"]
      warn "No daemons found at #{daemon_path}" if paths.empty?
      paths.map{|p| get_daemon_name(p) }
    end

  end

end

require 'daemon_objects/base'
require 'daemon_objects/consumer_base'
require 'daemon_objects/amqp_support'
require 'daemon_objects/railtie'

