module USerializer
  class HasOne
    def initialize(key, opts)
      @key = key
      @opts = opts
      @id_key = "#{key}_id".to_sym
      @root_key = opts[:root]&.to_sym

      serializer = opts[:serializer]
      @serializer = nil

      @serializer = if serializer&.is_a?(Proc)
                      @serializer = serializer
                    elsif serializer
                      proc { serializer }
                    end

      @embed_key = opts[:embed_key] || :id
      @conditional_block = opts[:if] || proc { true }
    end

    attr_reader :id_key, :key

    def merge_attributes(res, ser, opts)
      return unless @conditional_block.call(ser.object, opts)

      obj = ser.send(@key)
      res[@id_key] = obj.nil? ? nil : obj.send(@embed_key)
    end

    def merge_root(res, ser, opts)
      obj = ser.send(@key)

      return if obj.nil? || !@conditional_block.call(ser.object, opts)

      serializer(obj, opts).merge_root(res, root_key(obj), false, opts)
    end

    private

    def serializer(obj, opts)
      return @serializer.call(obj, opts).new(obj, @opts) if @serializer
      return obj.serialize if obj.respond_to?(:serialize)

      USerializer.infered_serializer_class(obj.class).new(obj, @opts)
    end

    def root_key(obj)
      return @root_key if @root_key

      ActiveSupport::Inflector.pluralize(
        ActiveSupport::Inflector.underscore(obj.class.name).split('/').last
      ).to_sym
    end
  end
end
