require 'ipaddr'

module Irrc
  module Irrd
    module Api
      private

      def persist_command
        '!!'
      end

      # Public: Returns a IRR command to specify authoritative IRR source.
      #
      # sources - Array object containing IRR source names.
      def set_source_command(sources)
        if sources && !sources.empty?
          "!s#{sources.join(',')}"
        else
          '!s-*'
        end
      end

      def expand_set_command(as_set)
        "!i#{as_set},1" if as_set && as_set != ''
      end

      def parse_aut_nums_from_as_set(result)
        case result
        when success_code
          result.gsub(/^#{$1}$/, '').strip.split.grep(/^AS/).uniq
        when error_code
          raise $1
        end
      end

      def parse_prefixes_from_route_set(result)
        case result
        when success_code
          prefixes = result.gsub(/^#{$1}$/, '').strip.split.reject {|p| p =~ /^A\d+$/ }.uniq
          prefixes.each_with_object(Struct.new(:ipv4, :ipv6).new([], [])) {|prefix, result|
            addr = IPAddr.new(prefix)
            if addr.ipv4?
              result.ipv4 << prefix
            elsif addr.ipv6?
              result.ipv6 << prefix
            end
          }
        when error_code
          raise $1
        end
      end

      def expand_aut_num_command(autnum)
        "-K -r -i origin #{autnum}" if autnum && autnum != ''
      end

      def parse_prefixes_from_aut_num(result, protocol)
        result.scan(route_tag(protocol)).flatten.uniq
      end

      # See http://www.irrd.net/irrd-user.pdf for return codes
      def success_code
        /^(C.*)\n$/
      end

      def error_code
        /^(D|E|F.*)\n$/
      end

      def return_code
        # Query with ripe option commands like "-i origin AS2515" returns doubled blank lines.
        # And we can't easily tell whether it succeeded or not.
        Regexp.union(success_code, error_code, /^\n\n$/)
      end

      def route_tag(protocol)
        case protocol
        when :ipv4, 'ipv4'
          /^route:\s*(\S+)$/
        when :ipv6, 'ipv6'
          /^route6:\s*(\S+)$/
        end
      end
    end
  end
end
