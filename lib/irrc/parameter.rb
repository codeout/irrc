module Irrc
  module Parameter

    # Public: Create a new IRRd / Whoisd client worker.
    #         You can customize the logger by specifying a block.
    #         The default logger is STDERR printer of more severe messages than INFO.
    #
    # host   - FQDN of IRR / Whois. IRR / Whois name is also accespted.
    # queue  - Queue object having query jobs.
    #          IRR /Whois name is also accespted.
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


    private

    def host=(host)
      raise ArgumentError, "Missing argument." unless host
      @host = Irrc::Irr.host(host) || host
    end

    def queue=(queue)
      queue.is_a?(Queue) or raise ArgumentError, "Missing argument."
      @queue = queue
    end
  end
end
