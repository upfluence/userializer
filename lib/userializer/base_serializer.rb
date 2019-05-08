require 'oj'
require 'active_support/inflector/methods'
require 'userializer/has_one'

module USerializer
  class BaseSerializer
    class << self
      def attributes(*keys)
        @attrs ||= [:id]
        @attrs += keys.map(&:to_sym)
        @attrs.compact!
      end

      def has_one(relation, opts = {})
        @relations ||= []
        @relations << HasOne.new(relation, opts)
      end

      def has_many(relation, opts = {})
        @relations ||= []
        @relations << HasMany.new(relation, opts)
      end

      attr_reader :attrs, :relations
    end

    def serializable_hash
      res = {}

      attribute_keys.each { |k| res[k] = fetch_obj(k) }
      relations.each { |rel| rel.merge_attributes(res, fetch_obj(rel.key)) }

      res
    end

    def merge_root(res, key, single)
      if single
        res[key] = serializable_hash
      else
        res[key] ||= []

        id = @obj.id

        if res[key].detect { |v| v[:id] == id }
          return
        else
          res[key] << serializable_hash
        end
      end

      relations.each do |rel|
        rel.merge_root(res, fetch_obj(rel.key))
      end
    end

    def to_hash
      res = {}

      merge_root(res, @root_key, true)

      res[:meta] = @meta if @meta

      res
    end

    def to_json
      Oj.dump(h)
    end

    def initialize(obj, opts = {})
      @obj = obj
      @opts = opts
      @meta = opts[:meta]
      @except = Set.new([opts[:except]].flatten.compact)

      @root_key = (opts[:root] || ActiveSupport::Inflector.underscore(
        obj.class.name
      ).split('/').last).to_sym
    end

    private

    def fetch_obj(key)
      self.class.method_defined?(key) ? send(key) : @obj.send(key)
    end

    def attribute_keys
      @attributes ||= ((self.class.attrs || []) << :id).reject do |k|
        @except.include?(k)
      end
    end

    def relations
      @relations ||= (self.class.relations || []).reject do |rel|
        @except.include?(rel.key)
      end
    end
  end
end
