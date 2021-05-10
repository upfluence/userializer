require 'userializer/version'
require 'userializer/base_serializer'
require 'userializer/array_serializer'
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

      (kls.name + 'Serializer').split(NS_SEPARATOR).inject(Object) do |o, c|
        o.const_get(c)
      end
    end
  end
end
