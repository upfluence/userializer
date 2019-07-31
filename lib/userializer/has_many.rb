module USerializer
  class HasMany
    attr_reader :key

    def initialize(key, opts)
      @key = key

      @opts = opts
      @id_key = "#{ActiveSupport::Inflector.singularize(key)}_ids".to_sym

      @embed_key = opts[:embed_key] || :id
      @conditional_block = opts[:if] || proc { true }
    end

    def merge_attributes(res, ser, opts)
      return unless @conditional_block.call(ser.object, opts)

      res[@id_key] = (entities(ser) || []).compact.map do |obj|
        obj.nil? ? nil : obj.send(@embed_key)
      end.compact
    end

    def merge_root(res, ser, opts)
      objs = entities(ser) || []

      return if objs.empty? || !@conditional_block.call(ser.object, opts)

      ArraySerializer.new(objs, @opts).merge_root(res, opts)
    end

    def entities(ser)
      obj = ser.send(@key) || []
      return obj unless @opts[:scope]

      obj.send(@opts[:scope])
    end
  end
end
