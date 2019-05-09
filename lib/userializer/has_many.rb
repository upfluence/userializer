module USerializer
  class HasMany
    attr_reader :key

    def initialize(key, opts)
      @key = key

      @opts = opts
      @id_key = "#{ActiveSupport::Inflector.singularize(key)}_ids".to_sym
    end

    def merge_attributes(res, objs)
      res[@id_key] = objs.compact.map(&:id).compact
    end

    def merge_root(res, objs)
      return if (objs || []).empty?

      ArraySerializer.new(objs, @opts).merge_root(res)
    end
  end
end
