require 'yaml'

module Irrc
  module Cli
    class YamlPrinter
      class << self
        def print(hash)
          puts hash.to_yaml
        end
      end
    end
  end
end
