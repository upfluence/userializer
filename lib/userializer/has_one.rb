module USerializer
  class HasOne
    def initialize(key, opts)
      @key = key
      @opts = opts
      @id_key = opts[:id_key] || "#{key}_id".to_sym
      @root_key = opts[:root]&.to_sym
      @root_keys = {}

      serializer = opts[:serializer]

      @serializer = if serializer&.is_a?(Proc)
                      @serializer = serializer
                    elsif serializer
                      proc { serializer }
                    end

      @embed_key = opts[:embed_key] || :id
      @conditional_block = opts[:if]
    end

    attr_reader :id_key, :key

    def merge_attributes(res, ser, opts)
      return unless allow?(ser, opts)

      obj = entity(ser)
      res[@id_key] = obj.nil? ? nil : obj.send(@embed_key)
    end

    def merge_root(res, ser, opts)
      return unless allow?(ser, opts)

      obj = entity(ser)

      return if obj.nil?

      serializer(obj, opts).merge_root(res, root_key(obj), false, opts)
    end

    def entity(ser)
      ser.relation_value(@key) { ser.send(@key) }
    end

    private

    def allow?(ser, opts)
      @conditional_block.nil? || @conditional_block.call(ser.object, opts)
    end

    def serializer(obj, opts)
      return @serializer.call(obj, opts).new(obj, @opts) if @serializer
      return obj.serialize if obj.respond_to?(:serialize)

      USerializer.infered_serializer_class(obj.class).new(obj, @opts)
    end

    def root_key(obj)
      return @root_key if @root_key

      name = obj.class.name

      @root_keys[name] ||= ActiveSupport::Inflector.pluralize(
        ActiveSupport::Inflector.underscore(name).split('/').last
      ).to_sym
    end
  end
end
