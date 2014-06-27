require 'irrc/irr'
require 'irrc/query_status'
require 'irrc/subquery'

module Irrc

  # Public: IRR / Whois query and result container.
  class Query
    include Irrc::Irr
    include Irrc::QueryStatus
    include Irrc::Subquery

    attr_reader :sources, :protocols

    # Public: Create a new Query object.
    #
    # object  - IRR object to extract. (eg: as-set, route-set, aut-num object)
    # options - The Hash options to pass to IRR. (default: {procotol: [:ipv4, :ipv6]})
    #           :source   - Specify authoritative IRR source names.
    #                       If not given, any source will be accepted. (optional)
    #           :protocol - :ipv4, :ipv6 or [:ipv4, :ipv6]
    #                       A String or Symbol of protcol name is acceptable. (optional)
    #
    # Examples
    #
    #   Irrc::Query.new('AS-JPNIC', source: :jpirr, protocol: :ipv4)
    #   Irrc::Query.new('AS-JPNIC', source: [:jpirr, :radb])
    def initialize(object, options={})
      options = {protocol: [:ipv4, :ipv6]}.merge(options)
      self.sources = options[:source]
      self.protocols = options[:protocol]
      self.object = object.to_s
    end

    def result
      @result ||= Struct.new(:ipv4, :ipv6).new
    end

    # Public: Register aut-num object(s) as a result.
    #
    # autnums - aut-num object(s) in String. Array form is also acceptable for multiple objects.
    def add_aut_num_result(autnums)
      @protocols.each do |protocol|
        result[protocol] ||= {}

        Array(autnums).each do |autnum|
          result[protocol][autnum] ||= []
        end
      end
    end

    # Public: Register route object(s) as a result.
    #
    # prefixes - route object(s) in String. Array form is also acceptable for multiple objects.
    # autnum   - Which aut-num has the route object(s).
    # protocol - Which protocol the route object(s) is for. :ipv4 or :ipv6.
    #            A String or Symbol of protcol name is acceptable.
    def add_prefix_result(prefixes, autnum, protocol)
      result[protocol] ||= {}
      result[protocol][autnum] ||= []
      result[protocol][autnum] |= Array(prefixes)
    end


    private

    def sources=(sources)
      @sources = Array(sources).compact.map(&:to_s).flatten.uniq
    end

    def protocols=(protocols)
      protocols = Array(protocols).compact.map(&:to_s).flatten.uniq
      invalid = protocols - ['ipv4', 'ipv6']
      raise ArgumentError, "Invalid protocol: #{invalid.join(', ')}" unless invalid.empty?
      @protocols = protocols
    end
  end
end
