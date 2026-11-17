require 'set'
require 'oj'
require 'active_support/inflector/methods'
require 'userializer/has_one'
require 'userializer/has_many'
require 'userializer/attribute'
require 'userializer/payload'

module USerializer
  class BaseSerializer
    class << self
      def inherited(subclass)
        subclass.attrs = self.attrs.dup || { id: Attribute.new(:id, {}, nil) }
        subclass.relations = self.relations.dup || {}
        subclass.serializer_methods = self.serializer_methods.dup || Set.new
      end

      # BaseSerializer itself has no registry, so its own methods are never
      # treated as serializer methods.
      def method_added(name)
        super
        serializer_methods&.add(name)
      end

      def include(*mods)
        super

        mods.each do |mod|
          serializer_methods&.merge(
            mod.instance_methods + mod.private_instance_methods
          )
        end

        self
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

      attr_accessor :attrs, :relations, :serializer_methods
    end

    attr_reader :obj, :meta, :opts

    alias object obj

    def initialize(obj, opts = {})
      @obj = obj
      @opts = opts
      @meta = opts[:meta]
      @except = key_filter(opts[:except])
      @only = key_filter(opts[:only])
    end

    def serializable_hash(opts)
      res = {}

      _attributes { |attr| attr.merge_attributes(res, self, opts) }
      _relations { |rel| rel.merge_attributes(res, self, opts) }

      res
    end

    def merge_root(res, key, single, opts)
      if single
        res[key] = serializable_hash(opts)
      else
        return if res.include_id?(key, @obj.id)

        res.push(key, serializable_hash(opts))
      end

      _relations { |rel| rel.merge_root(res, self, opts) }
    end

    def to_hash
      res = Payload.new

      merge_root(res, _root_key, true, @opts.slice(:scope))

      res[:meta] = @meta if @meta

      res.to_h
    end

    def read_attribute(key)
      return send(key) if self.class.serializer_methods.include?(key)

      @obj.send(key)
    end

    def relation_value(key)
      @_relation_values ||= {}

      return @_relation_values[key] if @_relation_values.key?(key)

      @_relation_values[key] = yield
    end

    def to_json
      Oj.dump(to_hash, mode: :compat)
    end

    def method_missing(mth); @obj.send(mth); end

    private

    def _root_key
      @_root_key ||= if @opts[:root]
                       @opts[:root].to_sym
                     else
                       USerializer.infered_singular_root_key(@obj.class)
                     end
    end

    def _attributes
      (self.class.attrs || {}).each_value do |attr|
        yield attr if allow?(attr.key)
      end
    end

    def _relations
      (self.class.relations || {}).each_value do |rel|
        yield rel if allow?(rel.key)
      end
    end

    def key_filter(keys)
      return if keys.nil?

      keys = [keys].flatten.compact

      Set.new(keys) unless keys.empty?
    end

    def allow?(key)
      return @only.include?(key) if @only
      return true unless @except

      !@except.include?(key)
    end
  end
end
