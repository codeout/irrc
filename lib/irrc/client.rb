require 'irrc/irr'
require 'irrc/irrd'
require 'irrc/whoisd'
require 'irrc/query'

module Irrc

  # Public: IRR / Whois client to manage child client workers and queues.
  class Client
    # Public: Create a new IRR / Whois client worker manager.
    #         You can customize the logger by specifying a block.
    #         The default logger is STDERR printer of more severe messages than INFO.
    #
    # threads - Number of threads to resolve prefixes per IRR / Whois server. (default: 1)
    # block   - An optional block that can be used to customize the logger.
    #
    # Examples
    #
    #   Irrc::Client.new(2) {|c|
    #     c.logger = Logger.new('irrc.log')
    #   }
    def initialize(threads=1, &block)
      @thread_limit = threads.to_i
      @block = block
    end

    # Public: Enqueue an IRR / Whois query.
    #
    # host    - FQDN of IRR / Whois server. IRR name is also acceptable. (eg: jpirr)
    # objects - IRR objects to extract. (eg: as-set, route-set, aut-num object)
    #           Array form is also acceptable for multiple objects.
    # options - The Hash options to pass to IRR. (default: {procotol: [:ipv4, :ipv6]})
    #           :source   - Specify authoritative IRR source names.
    #                       If not given, any source will be accepted. (optional)
    #           :protocol - :ipv4, :ipv6 or [:ipv4, :ipv6]
    #                       A String or Symbol of protcol name is acceptable. (optional)
    #
    # Examples
    #
    #   client.query :jpirr, 'AS-JPNIC', source: :jpirr, protocol: :ipv4
    #   client.query :jpirr, 'AS-JPNIC', source: [:jpirr, :radb]
    def query(host, objects, options={})
      raise ArgumentError, 'host is required.' unless host
      fqdn = Irrc::Irr.host(host) || host

      Array(objects).map {|object|
        queue(fqdn) << Irrc::Query.new(object, options)
      }
    end

    # Public: Run the query threads.
    #
    # Returns Raw level Array of Queries.
    def run
      done = []

      queues.each_with_object([]) {|(fqdn, queue), workers|
        @thread_limit.times.map.with_index {|i|
          workers << Thread.start {
            Thread.current[:id] = i+1
            done.push *worker_class(fqdn).new(fqdn, queue(fqdn), cache(fqdn), &@block).run(@thread_limit)
          }
        }
      }.each {|t| t.join }

      done
    end

    # Public: Run the query threads.
    #
    # Returns Decorated result Hash. See an example below:
    #
    #   {"as-jpnic"=>                 # IRR object to query
    #     {:ipv4=>                    # protocol
    #       {"AS2515"=>               # origin aut-num object
    #         ["202.12.30.0/24",      # prefixes
    #          "192.41.192.0/24",     #
    #          "211.120.240.0/21",    #
    #          "211.120.248.0/24"]},  #
    #      :ipv6=>
    #        {"AS2515"=>
    #          ["2001:dc2::/32",
    #           "2001:0fa0::/32",
    #           "2001:DC2::/32"]}}}
    def perform
      decorate(run)
    end


    private

    def queues
      @queues ||= {}
    end

    def queue(fqdn)
      queues[fqdn] ||= Queue.new
    end

    def caches
      @caches ||= {}
    end

    def cache(fqdn)
      caches[fqdn] ||= {}
    end

    def worker_class(fqdn)
      type = Irrc::Irr.type(fqdn) or raise "Unknown type of IRR for '#{fqdn}'."
      Module.const_get("Irrc::#{type.capitalize}::Client")
    end

    def decorate(queries)
      Hash[
        queries.map {|query|
          [query.object, query.result.to_h.select {|_, val| val }] if query.succeeded?
        }.compact
      ]
    end
  end
end
