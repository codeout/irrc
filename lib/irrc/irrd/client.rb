require 'net/telnet'

require 'irrc/connecting'
require 'irrc/logging'
require 'irrc/parameter'
require 'irrc/runner'
require 'irrc/socket'
require 'irrc/irrd/api'

module Irrc
  module Irrd

    # Public: IRRd client worker.
    class Client
      include Irrc::Connecting
      include Irrc::Logging
      include Irrc::Parameter
      include Irrc::Runner
      include Irrc::Irrd::Api

      attr_reader :host, :queue


      private

      def connect
        super
        connection.puts persist_command
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
        prefixes = classify_by_protocol(parse_prefixes_from_route_set(result))

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
