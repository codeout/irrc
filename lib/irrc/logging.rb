require 'logger'

module Irrc
  module Logging
    def logger=(logger)
      @logger = logger
    end

    def logger
      @logger ||= Logger.new(STDERR).tap {|l| l.level = Logger::WARN }
    end

    class Logger < ::Logger
      def add(severity, message = nil, progname = nil, &block)
        super(severity, message, "(#{Thread.current[:id]}) #{progname}")
      end
    end
  end
end
