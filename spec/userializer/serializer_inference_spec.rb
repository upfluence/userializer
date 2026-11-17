require 'spec_helper'

module SerializerInferenceTesting
  class Widget
    attr_accessor :id
  end

  class Gadget
    attr_accessor :id
  end

  class GadgetSerializer < USerializer::BaseSerializer
    attributes :namespaced do
      true
    end
  end
end

class WidgetSerializer < USerializer::BaseSerializer
  attributes :top_level do
    true
  end
end

class GadgetSerializer < USerializer::BaseSerializer
  attributes :top_level do
    true
  end
end

RSpec.describe USerializer do
  context 'serializer in the model namespace' do
    it do
      expect(
        USerializer.infered_serializer_class(SerializerInferenceTesting::Gadget)
      ).to eq(SerializerInferenceTesting::GadgetSerializer)
    end
  end

  context 'serializer at the top level' do
    it do
      expect(
        USerializer.infered_serializer_class(SerializerInferenceTesting::Widget)
      ).to eq(WidgetSerializer)
    end
  end

  context 'sideloads with a top level serializer' do
    it do
      widget = SerializerInferenceTesting::Widget.new
      widget.id = 1

      expect(USerializer::ArraySerializer.new([widget]).to_hash).to eq(
        widgets: [{ id: 1, top_level: true }]
      )
    end
  end
end
