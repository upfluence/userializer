module USerializer
  class HasMany
    attr_reader :key

    def initialize(key, opts)
      @key = key

      @opts = opts
      @ids_key = opts[:ids_key] || build_ids_key(key)

      @embed_key = opts[:embed_key] || :id
      @conditional_block = opts[:if]
    end

    def merge_attributes(res, ser, opts)
      return unless allow?(ser, opts)

      res[@ids_key] = (entities(ser) || []).compact.map do |obj|
        obj.send(@embed_key)
      end.compact
    end

    def merge_root(res, ser, opts)
      return unless allow?(ser, opts)

      objs = entities(ser) || []

      return if objs.empty?

      ArraySerializer.new(objs, @opts).merge_root(res, opts)
    end

    def entities(ser)
      ser.relation_value(@key) do
        obj = ser.send(@key) || []

        @opts[:scope] ? obj.send(@opts[:scope]) : obj
      end
    end

    private

    def allow?(ser, opts)
      @conditional_block.nil? || @conditional_block.call(ser.object, opts)
    end

    def build_ids_key(key)
      "#{ActiveSupport::Inflector.singularize(key)}_ids".to_sym
    end
  end
end
