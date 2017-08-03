module DaemonObjects
  class Configuration

    attr_accessor :error_handler, :log_to_stdout

    def initialize
      @error_handler = Proc.new{|e| nil }
      @log_to_stdout = false
    end

    def handle_error(error)
      @error_handler.call(error) if @error_handler
    end

  end
end
