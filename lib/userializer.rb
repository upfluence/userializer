require 'userializer/version'
require 'userializer/base_serializer'
require 'userializer/array_serializer'
require 'userializer/raw_serializer'
require 'userializer/composite_serializer'

module USerializer
  NS_SEPARATOR = '::'.freeze

  @root_keys = {}

  class << self
    def serializer_for(obj)
      return nil if obj.nil?

      infered_serializer_class(obj.class)
    end

    def infered_serializer_class(kls)
      return nil if kls.nil?

      name = "#{kls.name}Serializer"

      return Object.const_get(name) if Object.const_defined?(name)

      name.split(NS_SEPARATOR).inject(Object) { |o, c| o.const_get(c) }
    end

    def infered_root_key(kls)
      name = kls.name

      @root_keys[name] ||= ActiveSupport::Inflector.pluralize(
        ActiveSupport::Inflector.underscore(name).split('/').last
      ).to_sym
    end
  end
end
