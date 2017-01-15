module Irrc
  module Runner
    def run
      done = []

      loop do
        if @queue.empty?
          close
          return done
        end

        query = @queue.pop
        connect unless established?

        begin
          query = process(query)
          query.success
          query.children.each {|q| @queue << q }
        rescue
          logger.error $!.message
          query.fail
        end

        done << query if query.root?
      end
    end


    private

    def cache(object, sources, &block)
      @cache["#{object}:#{sources}"] ||= yield
    end

    def execute(command)
      return if command.nil? || command == ''

      logger.debug "Executing: #{command}"
      connection.cmd(command).tap {|result| logger.debug "Returned: #{result}" }
    end
  end
end
