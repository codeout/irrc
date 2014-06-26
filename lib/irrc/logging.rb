require 'logger'

module Irrc
  module Logging
    def logger=(logger)
      @logger = logger
    end

    def logger
      @logger ||= Logger.new(STDERR).tap {|l| l.level = Logger::WARN }
    end
  end
end
