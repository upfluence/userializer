require 'oj'
require 'active_support/inflector/methods'
require 'userializer/has_one'
require 'userializer/has_many'
require 'userializer/attribute'

module USerializer
  class BaseSerializer
    class << self
      def inherited(subclass)
        subclass.attrs = self.attrs.dup || { id: Attribute.new(:id, {}, nil) }
        subclass.relations = self.relations.dup || {}
      end

      def attributes(*attrs, &block)
        attrs = attrs.first if attrs.first.class.is_a?(Array)
        opts = attrs.last.is_a?(Hash) ? attrs.pop : {}

        attrs.each { |attr| @attrs[attr] = Attribute.new(attr, opts, block) }
      end

      def has_one(*attrs)
        attrs = attrs.first if attrs.first.class.is_a?(Array)
        opts = attrs.last.is_a?(Hash) ? attrs.pop : {}

        attrs.each { |attr| @relations[attr] = HasOne.new(attr, opts) }
      end

      def has_many(*attrs)
        attrs = attrs.first if attrs.first.class.is_a?(Array)
        opts = attrs.last.is_a?(Hash) ? attrs.pop : {}

        attrs.each { |attr| @relations[attr] = HasMany.new(attr, opts) }
      end

      attr_accessor :attrs, :relations
    end

    attr_reader :obj, :meta, :opts

    alias object obj

    def initialize(obj, opts = {})
      @obj = obj
      @opts = opts
      @meta = opts[:meta]
      @except = Set.new([opts[:except]].flatten.compact)

      @root_key = (opts[:root] || ActiveSupport::Inflector.underscore(
        obj.class.name
      ).split('/').last).to_sym
    end

    def serializable_hash(opts)
      res = {}

      attributes.each { |attr| attr.merge_attributes(res, self, opts) }
      relations.each do |rel|
        rel.merge_attributes(res, self, opts)
      end

      res
    end

    def merge_root(res, key, single, opts)
      if single
        res[key] = serializable_hash(opts)
      else
        res[key] ||= []

        id = @obj.id

        if res[key].detect { |v| id && v[:id] == id }
          return
        else
          res[key] << serializable_hash(opts)
        end
      end

      relations.each { |rel| rel.merge_root(res, self, opts) }
    end

    def to_hash
      res = {}

      merge_root(res, @root_key, true, @opts.slice(:scope))

      res[:meta] = @meta if @meta

      res
    end

    def to_json
      Oj.dump(to_hash, mode: :compat)
    end

    def method_missing(mth); @obj.send(mth); end

    private

    def attributes
      @attributes ||= (self.class.attrs || {}).values.reject do |attr|
        @except.include?(attr.key)
      end
    end

    def relations
      @relations ||= (self.class.relations || {}).values.reject do |rel|
        @except.include?(rel.key)
      end
    end
  end
end
