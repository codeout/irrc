module Irrc
  module Subquery
    # Public: Generate a child query to resolve IRR / Whois object recursively.
    #
    # object  - IRR / Whois object to extract. (eg: as-set, route-set, aut-num object)
    def fork(object)
      Query.new(object, source: sources, protocol: protocols).tap {|q|
        q.parent = self
      }
    end

    # Public: Returns the parent (associated) Query object, which is probably as-set.
    def parent
      @_parent
    end

    # Public: Set a parent (associated) Query object, which is probably as-set.
    #
    # parent - Parent Query object.
    def parent=(parent)
      @_parent = parent
    end
  end
end
