module Irrc
  module Connecting
    private

    def connection
      @connection
    end

    def connection=(connection)
      @connection = connection
    end

    def connect
      @connection ||= logger.info("Connecting to #{@fqdn}") &&
        Net::Telnet.new('Host' => @fqdn,
        'Port' => 43,
        'Telnetmode' => false,
        'Prompt' => return_code)
    end

    def close
      if established?
        logger.info "Closing a connection to #{@fqdn}"
        @connection.close
      end
    end

    def established?
      @connection && !@connection.sock.closed?
    end
  end
end
