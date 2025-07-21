require 'oj'

module USerializer
  class CompositeObject
    def initialize(obj, opts = {})
      @obj = obj
      @opts = opts
      @root_key = opts[:root].to_sym
      serializer = opts[:serializer]
      @serializer = if serializer.is_a?(Proc)
                      serializer
                    elsif serializer
                      proc { serializer }
                    end
    end

    def merge_root(res, opts)
      serializer(@obj, opts).merge_root(res, @root_key, true, opts)
    end

    private

    def serializer(obj, opts)
      return @serializer.call(obj, opts).new(obj, @opts) if @serializer
      return obj.serialize if obj.respond_to?(:serialize)

      USerializer.infered_serializer_class(obj.class).new(obj, @opts)
    end
  end

  class CompositeSerializer
    def initialize(objs, opts = {})
      @opts = opts
      @objs = compose_objs(objs)
    end

    def merge_root(res, opts)
      @objs.each do |obj|
        obj.merge_root(res, opts)
      end
    end

    def to_hash
      res = {}

      merge_root(res, @opts)
      res
    end

    def serialize(*_args)
      to_hash
    end

    def to_json(*_args)
      Oj.dump(to_hash, mode: :compat)
    end

    private

    def compose_objs(objs)
      objs.map do |(key, obj)|
        opts = options_for(key)

        if obj.is_a?(Hash) || !obj.is_a?(Enumerable)
          CompositeObject.new(obj, opts)
        else
          ArraySerializer.new(obj, opts, embed_empty_array: true)
        end
      end
    end

    def options_for(key)
      @opts.reduce({}) do |acc, (opt_key, values)|
        acc.merge(opt_key.to_sym => values[key.to_sym])
      end.compact.merge(root: key) { |_, x, y| x || y }
    end
  end
end
