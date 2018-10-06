module Irrc
  module Runner
    def run(threads)
      done = []

      loop do
        # Trick to avoid dead lock
        if last_thread_of?(threads) && @queue.empty?
          terminate

          # Queue guard objects notifying other threads to return results
          logger.debug "Queue #{threads - 1} guard objects"
          (threads - 1).times { @queue.push nil }

          return done
        end

        query = @queue.pop

        # Trick to avoid dead lock
        if query.nil?
          terminate
          return done
        end

        connect unless established?

        begin
          logger.info "Processing #{query.object}"
          query = process(query)
          query.success
          logger.debug "Queue new #{query.children.size} queries"
          query.children.each {|q| @queue << q }
        rescue
          logger.error "#{$!.message} when processing #{query.object} for #{query.root.object}"
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

      logger.debug %(Executing "#{command}")
      connection.cmd(command).tap {|result| logger.debug %(Got "#{result}") }
    end

    def last_thread_of?(num_threads)
      return @queue.num_waiting == num_threads - 1
    end

    def terminate
      logger.info "No more queries"
      close
    end
  end
end
