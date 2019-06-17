require 'irrc/irr'

module Irrc
  module Whoisd
    module Api
      private

      def expand_set_command(as_set, sources, type)
        "-k -r #{source_option(sources)} -T #{type} #{as_set}"
      end

      def parse_objects_from_set(result)
        if result =~ error_code
          raise $1
        end

        result.scan(Irrc::Irr.members_tag).flatten.map {|i|
               i.gsub(/#.*/,"").split(/\s*,?\s+/)}.flatten
      end

      def expand_route_set_command(route_set, sources)
        if sources && !sources.empty?
          "-k -r -s #{sources.join(',')} -T route-set #{route_set}"
        else
          "-k -r -a -T route-set #{route_set}"
        end
      end

      def expand_aut_num_command(autnum, sources)
        "-k -r #{source_option(sources)} -K -i origin #{autnum}"
      end

      def parse_prefixes_from_aut_num(result, protocol)
       result.scan(Irrc::Irr.route_tag(protocol)).flatten.uniq
      end

      # See http://www.ripe.net/data-tools/support/documentation/ripe-database-query-reference-manual#a1--ripe-database-query-server-response-codes-and-messages for the error code
      def error_code
        /^%ERROR:(.*)$/
      end

      def return_code
        /\n\n\n/
      end

      def source_option(sources)
        if sources && !sources.empty?
          "-s #{sources.join(',')}"
        else
          '-a'
        end
      end
    end
  end
end
