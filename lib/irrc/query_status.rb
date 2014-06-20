module Irrc
  module QueryStatus
    def fail
      @failed = true
    end

    def success
      @failed = false
    end

    def failed?
      @failed
    end

    def succeeded?
      @failed == false
    end
  end
end
