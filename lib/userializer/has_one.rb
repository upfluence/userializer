module USerializer
  class HasOne
    def initialize(key, opts)
      @key = key
      @opts = opts
      @id_key = "#{key}_id".to_sym
      @root_key = opts[:root]&.to_sym

      @serializer = opts[:serializer]
    end

    attr_reader :id_key, :key

    def merge_attributes(res, obj)
      res[@id_key] = obj&.id
    end

    def merge_root(res, obj)
      return if obj.nil?

      serializer(obj).merge_root(res, root_key(obj), false)
    end

    private

    def serializer(obj)
      return @serializer.new(obj, @opts) if @serializer
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
