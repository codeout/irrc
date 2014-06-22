require 'net/telnet'

require 'irrc/irrd/api'
require 'irrc/logging'
require 'irrc/socket'

module Irrc
  module Irrd

    # Public: IRR client worker.
    class Client
      include Irrc::Logging
      include Irrc::Irrd::Api

      attr_reader :host, :queue

      # Public: Create a new IRR client worker.
      #         You can customize the logger by specifying a block.
      #         The default logger is STDERR printer of more severe messages than INFO.
      #
      # host   - FQDN of IRR. IRR name is also accespted.
      # queue  - Queue object having query jobs.
      #          IRR name is also accespted.
      # block  - An optional block that can be used to customize the logger.
      #
      # Examples
      #
      #   Irrc::Irrd::Client.new('jpirr.nic.ad.jp', queue) {|c|
      #     c.logger = Logger.new('irrc.log')
      #   }
      def initialize(host, queue, &block)
        self.host = host
        self.queue = queue
        instance_eval(&block) if block_given?
      end

      def run
        done = []

        loop do
          if queue.empty?
            close
            return done
          end

          query = queue.pop
          connect unless established?

          begin
            process query
            query.success
          rescue
            logger.error $!.message
            query.fail
          end

          done << query
        end
      end


      private

      def host=(host)
        raise ArgumentError, "Missing argument." unless host
        @host = Irrc::Irr.host(host) || host
      end

      def queue=(queue)
        queue.is_a?(Queue) or raise ArgumentError, "Missing argument."
        @queue = queue
      end

      def connect
        @connection ||= logger.info("Connecting to #{@host}") &&
          Net::Telnet.new('Host' => @host,
                          'Port' => 43,
                          'Telnetmode' => false,
                          'Prompt' => return_code)
        @connection.puts persist_command
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

      def process(query)
        set_source query

        case query.object_type
        when 'as-set'
          aut_nums_from_as_set query
          prefixes_from_aut_nums query
        when 'route-set'
          prefixes_from_route_set query
        when 'aut-num'
          query.add_aut_num_result query.object
          prefixes_from_aut_nums query
        end
      end

      def set_source(query)
        command = set_source_command(query.sources)
        if execute(command) =~ error_code
          raise "'#{command}' failed on '#{host}' (#{$1})."
        end
      end

      def aut_nums_from_as_set(query)
        command = expand_set_command(query.object)
        result = execute(command)
        query.add_aut_num_result parse_aut_nums_from_as_set(result)
      rescue
        raise "'#{command}' failed on '#{host}' (#{$!.message})."
      end

      def prefixes_from_route_set(query)
        command = expand_set_command(query.object)
        result = execute(command)
        prefixes = parse_prefixes_from_route_set(result)

        query.protocols.each do |protocol|
          query.add_prefix_result prefixes[protocol], nil, protocol
        end
      rescue
        raise "'#{command}' failed on '#{host}' (#{$!.message})."
      end

      def prefixes_from_aut_nums(query)
        unless query.protocols.empty?
          # ipv4 and ipv6 should have the same result so far
          (query.result[:ipv4] || query.result[:ipv6]).keys.each do |autnum|
            command = expand_aut_num_command(autnum)
            result = execute(command)

            query.protocols.each do |protocol|
              query.add_prefix_result parse_prefixes_from_aut_num(result, protocol), autnum, protocol
            end
          end
        end
      end
    end
  end
end
