require 'set'

module USerializer
  class Payload < Hash
    def []=(key, value)
      @ids&.delete(key)
      super
    end

    def include_id?(key, id)
      return false unless id

      ids(key).include?(id)
    end

    def push(key, value)
      (self[key] ||= []) << value
      ids(key) << value[:id]
    end

    private

    def ids(key)
      @ids ||= {}
      @ids[key] ||= Set.new((self[key] || []).map { |v| v[:id] })
    end
  end
end
