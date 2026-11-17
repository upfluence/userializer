require 'spec_helper'

module ArraySerializerTesting
  class Foo
    attr_accessor :id, :bar

    def initialize(id, bar)
      @id = id
      @bar = bar
    end
  end

  class FooSerializer < USerializer::BaseSerializer
    attributes :bar
  end

  class FooCustomSerializer < USerializer::BaseSerializer
    attributes :bar do |object, _|
      "custom #{object.bar}"
    end
  end
end

RSpec.describe USerializer::ArraySerializer do
  let(:foos) { [ArraySerializerTesting::Foo.new(1, 'bar')] }

  context 'options as a hash' do
    it do
      expect(
        USerializer::ArraySerializer.new(
          foos,
          { root: :items, meta: { total: 1 } }
        ).to_hash
      ).to eq(items: [{ id: 1, bar: 'bar' }], meta: { total: 1 })
    end
  end

  context 'options as keywords' do
    it do
      expect(
        USerializer::ArraySerializer.new(
          foos,
          root:            'items',
          meta:            { total: 1 },
          each_serializer: ArraySerializerTesting::FooCustomSerializer
        ).to_hash
      ).to eq(items: [{ id: 1, bar: 'custom bar' }], meta: { total: 1 })
    end
  end

  context 'embeds an empty array' do
    it do
      res = {}

      USerializer::ArraySerializer.new(
        [], root: :items, embed_empty_array: true
      ).merge_root(res, {})

      expect(res).to eq(items: [])
    end
  end
end
