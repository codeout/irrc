require 'ipaddr'

module Irrc
  module Prefix
    private

    def classify_by_protocol(prefixes)
      prefixes.each_with_object(Struct.new(:ipv4, :ipv6).new([], [])) {|prefix, result|
        addr = IPAddr.new(prefix)
        if addr.ipv4?
          result.ipv4 << prefix
        elsif addr.ipv6?
          result.ipv6 << prefix
        end
      }
    end
  end
end

