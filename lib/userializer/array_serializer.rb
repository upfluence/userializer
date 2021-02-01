require 'oj'

module USerializer
  class HeterogeneousArray < StandardError; end

  class ArraySerializer
    def initialize(objs, opts = {})
      @objs = objs.compact
      @opts = opts
      @meta = opts[:meta]

      clss = @objs.map(&:class).uniq
      obj_class = clss.first

      raise HeterogeneousArray if clss.count > 1

      @root_key = opts[:root]
      @root_key ||= ActiveSupport::Inflector.pluralize(
        ActiveSupport::Inflector.underscore(obj_class.name).split('/').last
      ).to_sym if obj_class

      serializer = opts[:each_serializer]

      @serializer = if serializer&.is_a?(Proc)
                      serializer
                    elsif serializer
                      proc { serializer }
                    end
    end

    def merge_root(res, opts)
      @objs.each do |obj|
        serializer(obj, opts).merge_root(res, @root_key, false, opts)
      end
    end

    def to_hash
      res = {}

      res[@root_key] = [] if @root_key

      merge_root(res, @opts)
      res[:meta] = @meta if @meta

      res
    end

    def to_json
      Oj.dump(to_hash, mode: :compat)
    end

    def scope; @opts[:scope]; end

    private

    def serializer(obj, opts)
      return @serializer.call(obj, opts).new(obj, @opts) if @serializer
      return obj.serialize if obj.respond_to?(:serialize)

      USerializer.infered_serializer_class(obj.class).new(obj, @opts)
    end
  end
end
