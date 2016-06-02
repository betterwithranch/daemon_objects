module DaemonObjects
  module Test
    module BunnyChannelExtensions

      def on_error(&block); end

      def ack(delivery_tag, multiple=false)
        ack_tags << delivery_tag
      end
      alias :acknowledge :ack 

      def reject(delivery_tag, requeue=false)
        reject_tags << delivery_tag
      end

      def ack_tags
        @ack_tags ||= []
      end

      def reject_tags
        @reject_tags ||= []
      end
    end

  end
end

BunnyMock::Channel.include(DaemonObjects::Test::BunnyChannelExtensions)
