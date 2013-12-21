module Yaks
  class NullResource
    include Enumerable

    def each
      return to_enum unless block_given?
    end

    def [](*)
    end

    def collection?
      false
    end
  end
end