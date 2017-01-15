require 'net/telnet'

require 'irrc/connecting'
require 'irrc/logging'
require 'irrc/parameter'
require 'irrc/prefix'
require 'irrc/runner'
require 'irrc/socket'
require 'irrc/whoisd/api'

module Irrc
  module Whoisd

    # Public: Whoisd client worker.
    class Client
      include Irrc::Connecting
      include Irrc::Logging
      include Irrc::Parameter
      include Irrc::Prefix
      include Irrc::Runner
      include Irrc::Whoisd::Api


      private

      def process(query)
        case query.object_type
        when 'as-set'
          expand_set query, 'as-set'
        when 'route-set'
          expand_set query, 'route-set'
        when 'aut-num'
          expand_aut_num query
        end

        query
      end

      # Public: Expand an as-set or route-set object into any object.
      def expand_set(query, type)
        result = cache(query.object, query.sources) {
          begin
            command = expand_set_command(query.object, query.sources, type)
            execute(command)
          rescue
            raise "'#{command}' failed on '#{@fqdn}' (#{$!.message})."
          end
        }

        parse_objects_from_set(result).each do |object|
          next if query.ancestor_object?(object)

          child = query.fork(object)

          case child.object_type
          when 'aut-num'
            query.add_aut_num_result object
          when nil  # it looks prefix which is a member of route-set
            prefix = classify_by_protocol(object)
            query.protocols.each do |protocol|
              query.add_prefix_result prefix[protocol], nil, protocol
            end
          end
        end
      end

      # Public: Expand an aut-num object into routes
      def expand_aut_num(query)
        return if query.protocols.empty?

        result = cache(query.object, query.sources) {
          begin
            command = expand_aut_num_command(query.object, query.sources)
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
