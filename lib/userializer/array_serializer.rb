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

      @root_key = opts[:root] || ActiveSupport::Inflector.pluralize(
        ActiveSupport::Inflector.underscore(obj_class.name).split('/').last
      ).to_sym

      @serializer = opts[:each_serializer] || USerializer.infered_serializer_class(
        obj_class
      )
    end

    def merge_root(res, opts)
      @objs.each do |obj|
        @serializer.new(obj, @opts).merge_root(res, @root_key, false, opts)
      end
    end

    def to_hash
      res = {}

      merge_root(res, @opts)
      res[:meta] = @meta if @meta

      res
    end

    def to_json
      Oj.dump(to_hash, mode: :compat)
    end

    def scope; @opts[:scope]; end
  end
end
