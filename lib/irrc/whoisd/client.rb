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
          query.add_aut_num_result objects_from_set(query, 'as-set')
          resolve_prefixes_from_aut_nums query
        when 'route-set'
          resolve_prefixes_from_route_set query
        when 'aut-num'
          query.add_aut_num_result query.object
          resolve_prefixes_from_aut_nums query
        end
      end

      def objects_from_set(query, type)
        command = expand_set_command(query.object, query.sources, type)
        cache(query.object) {
          result = execute(command)
          parse_objects_from_set(result).map {|object|
            expand_if_necessary(query.fork(object), type) unless query.ancestor_object?(object)
          }.flatten.uniq.compact
        }
      rescue
        raise "'#{command}' failed on '#{@fqdn}' (#{$!.message})."
      end

      def expand_if_necessary(query, type)
        if query.object_type == type
          objects_from_set(query, type)
        else
          query.object
        end
      end

      def resolve_prefixes_from_route_set(query)
        prefixes = classify_by_protocol(objects_from_set(query, 'route-set'))
        query.protocols.each do |protocol|
          query.add_prefix_result prefixes[protocol], nil, protocol
        end
      end

      def resolve_prefixes_from_aut_nums(query)
        unless query.protocols.empty?
          # ipv4 and ipv6 should have the same result so far
          (query.result[:ipv4] || query.result[:ipv6]).keys.each do |autnum|
            command = expand_aut_num_command(autnum, query.sources)
            result = execute(command)

            query.protocols.each do |protocol|
              query.add_prefix_result parse_prefixes_from_aut_num(result, protocol), autnum, protocol
            end
          end
        end
      end

      def cache(object, &block)
        @_cache ||= {}
        @_cache[object] ||= yield
      end
    end
  end
end
