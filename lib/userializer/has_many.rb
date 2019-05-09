module USerializer
  class HasMany
    attr_reader :key

    def initialize(key, opts)
      @key = key

      @opts = opts
      @id_key = "#{ActiveSupport::Inflector.singularize(key)}_ids".to_sym

      @conditional_block = opts[:if] || proc { true }
    end

    def merge_attributes(res, ser, opts)
      return unless @conditional_block.call(ser.object, opts)

      res[@id_key] = (ser.send(@key) || []).compact.map(&:id).compact
    end

    def merge_root(res, ser, opts)
      objs = ser.send(@key) || []

      return if objs.empty? || !@conditional_block.call(ser.object, opts)

      ArraySerializer.new(objs, @opts).merge_root(res, opts)
    end
  end
end
