require 'net/telnet'

require 'irrc/connecting'
require 'irrc/logging'
require 'irrc/parameter'
require 'irrc/prefix'
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
      include Irrc::Prefix
      include Irrc::Runner
      include Irrc::Irrd::Api


      private

      def connect
        super
        connection.puts persist_command
      end

      def process(query)
        set_source query

        case query.object_type
        when 'as-set'
          expand_as_set query
        when 'route-set'
          expand_route_set query
        when 'aut-num'
          expand_aut_num query
        end

        query
      end

      def set_source(query)
        command = set_source_command(query.sources)
        if execute(command) =~ error_code
          raise "'#{command}' failed on '#{@fqdn}' (#{$1})."
        end
      end

      # Public: Expand an as-set object into aut-nums
      def expand_as_set(query)
        result = cache(query.object, query.sources) {
          begin
            command = expand_set_command(query.object)
            execute(command)
          rescue
            raise "'#{command}' failed on '#{@fqdn}' (#{$!.message})."
          end
        }

        parse_aut_nums_from_as_set(result).each do |autnum|
          child = query.fork(autnum)
          query.add_aut_num_result autnum if child.aut_num?
        end
      end

      # Public: Expand a route-set into routes
      def expand_route_set(query)
        result = cache(query.object, query.sources) {
          begin
            command = expand_set_command(query.object)
            execute(command)
          rescue
            raise "'#{command}' failed on '#{@fqdn}' (#{$!.message})."
          end
        }

        prefixes = classify_by_protocol(parse_prefixes_from_route_set(result))

        query.protocols.each do |protocol|
          query.add_prefix_result prefixes[protocol], nil, protocol
        end
      end

      # Public: Expand an aut-num object into routes
      def expand_aut_num(query)
        return if query.protocols.empty?

        result = cache(query.object, query.sources) {
          begin
            command = expand_aut_num_command(query.object)
            execute(command)
          rescue
            raise "'#{command}' failed on '#{@fqdn}' (#{$!.message})."
          end
        }

        query.protocols.each do |protocol|
          query.add_prefix_result parse_prefixes_from_aut_num(result, protocol), query.object, protocol
        end
      end
    end
  end
end
