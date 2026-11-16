require 'userializer/version'
require 'userializer/base_serializer'
require 'userializer/array_serializer'
require 'userializer/raw_serializer'
require 'userializer/composite_serializer'

module USerializer
  NS_SEPARATOR = '::'.freeze

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
  end
end
