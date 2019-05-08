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

      @serializer = opts[:each_serializer] || infered_serializer_class(
        obj_class
      )
    end

    def merge_root(res)
      @objs.each do |obj|
        @serializer.new(obj, @opts).merge_root(res, @root_key, false)
      end
    end

    def to_hash
      res = {}

      merge_root(res)
      res[:meta] = @meta if @meta

      res
    end

    def to_json
      Oj.dump(h)
    end
  end
end
