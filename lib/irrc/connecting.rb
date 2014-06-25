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
      @connection ||= logger.info("Connecting to #{@host}") &&
        Net::Telnet.new('Host' => @host,
        'Port' => 43,
        'Telnetmode' => false,
        'Prompt' => return_code)
    end

    def close
      if established?
        logger.info "Closing a connection to #{@host}"
        @connection.close
      end
    end

    def established?
      @connection && !@connection.sock.closed?
    end

    def execute(command)
      return if command.nil? || command == ''

      logger.debug "Executing: #{command}"
      @connection.cmd(command).tap{|result| logger.debug "Returned: #{result}" }
    end
  end
end
