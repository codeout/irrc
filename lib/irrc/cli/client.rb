require 'optparse'

require 'irrc'
require 'irrc/cli/yaml_printer'

module Irrc
  module Cli
    class Client
      def initialize(args)
        @args = args
        @options = Struct.new(:host, :source, :protocol, :threads, :debug).new(nil, [], [], 1, nil)
      end

      def start
        OptionParser.new(&method(:options)).parse!(@args)

        verify_arguments
        set_default_arguments

        Irrc::Cli::YamlPrinter.print perform
      end


      private

      def options(opts)
        opts.banner = <<-EOS
Usage: #{opts.program_name} [options] [objects ...]

Description:
  Better IRR client to resolve as-set, route-set or aut-num object into prefixes.

  If no [-4|-6|--ipv4|--ipv6] option given, it tries both of ipv4 and ipv6.

Options:
        EOS

        opts.on '-h HOST', 'Specify FQDN of IRR / Whois server to send queries.',
                           'IRR / Whois name is also acceptable. This switch is mandatory.' do |host|
          @options.host = host
        end

        opts.on '-s SOURCE', '--source', 'Specify an authoritative IRR / Whois source name.',
                                         'Multiply this option for multiple SOURCE.',
                                         "eg) #{opts.program_name} -s jpirr -s radb AS-JPNIC" do |source|
          @options.source |= [source]
        end

        opts.on '-4', '--ipv4', 'Resolve IPv4 prefixes.' do
          @options.protocol |= [:ipv4]
        end

        opts.on '-6', '--ipv6', 'Resolve IPv6 prefixes.' do
          @options.protocol |= [:ipv6]
        end

        opts.on '-t NUMBER', '--threads', 'Number of threads to resolve prefixes per IRR / Whois server.' do |threads|
          @options.threads = threads
        end

        opts.on '-d', '--debug', 'Print raw queries, answers and additional informations.' do
          @options.debug = true
        end
      end

      def verify_arguments
        if @args.empty?
          $stderr.puts <<-EOS
Missing Argument: objects required.

Use --help for usage.
          EOS
          exit 1
        end

        unless @options.host
          $stderr.puts <<-EOS
Missing Argument: -h option is required.

Use --help for usage.
          EOS
          exit 1
        end
      end

      def set_default_arguments
        @options.protocol = [:ipv4, :ipv6] if @options.protocol.empty?
      end

      def perform
        client = if @options.debug
                   Irrc::Client.new(@options.threads) {|c| c.logger = Logger.new(STDERR) }
                 else
                   Irrc::Client.new(@options.threads)
                 end

        begin
          client.query(@options.host, @args, source: @options.source, protocol: @options.protocol)
          client.perform
        rescue
          $stderr.puts $!.message
          exit 1
        end
      end
    end
  end
end
