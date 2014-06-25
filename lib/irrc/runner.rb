module Irrc
  module Runner
    def run
      done = []

      loop do
        if queue.empty?
          close
          return done
        end

        query = queue.pop
        connect unless established?

        begin
          process query
          query.success
        rescue
          logger.error $!.message
          query.fail
        end

        done << query
      end
    end


    private

    def execute(command)
      return if command.nil? || command == ''

      logger.debug "Executing: #{command}"
      connection.cmd(command).tap{|result| logger.debug "Returned: #{result}" }
    end
  end
end
