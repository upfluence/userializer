module USerializer
  class Payload < Hash
    def []=(key, value)
      @ids&.delete(key)
      super
    end

    def include_id?(key, id)
      return false unless id

      ids(key).key?(id)
    end

    def push(key, value)
      (self[key] ||= []) << value
      ids(key)[value[:id]] = true
    end

    private

    def ids(key)
      @ids ||= {}
      @ids[key] ||= (self[key] || []).each_with_object({}) do |v, acc|
        acc[v[:id]] = true
      end
    end
  end
end
