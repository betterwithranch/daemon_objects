module DaemonObjects
  class Configuration

    attr_accessor :error_handler

    def initialize
      @error_handler = Proc.new{|e| nil }
    end

    def handle_error(error)
      @error_handler.call(error) if @error_handler
    end
  end
end
