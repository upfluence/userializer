require 'spec_helper'

module CompositeTesting
  class FooSerializer < USerializer::BaseSerializer
    attributes :bar
  end

  class FooSubSerializer < FooSerializer
    has_many :bazs
  end

  class FooCustomSerializer < USerializer::BaseSerializer
    attributes :bar do |object|
      "custom #{object.bar}"
    end
  end

  class Foo
    attr_accessor :id, :bar, :bazs
  end
end

RSpec.describe USerializer::CompositeSerializer do
  let(:foo) do
    foo = CompositeTesting::Foo.new
    foo.id = 1
    foo.bar = 'bar'

    foo
  end

  context 'serialize array value' do
    it do
      expect(
        USerializer::CompositeSerializer.new({ key: [foo] }).to_hash
      ).to eq(key: [{ id: 1, bar: 'bar' }])
    end

    context 'custom options' do
      it do
        expect(
          USerializer::CompositeSerializer.new(
            { key: [foo] },
            each_serializer: { key: CompositeTesting::FooCustomSerializer },
            root:            { key: :foofoo }
          ).to_hash
        ).to eq(foofoo: [{ id: 1, bar: 'custom bar' }])
      end
    end
  end

  context 'serialize single value' do
    it do
      expect(
        USerializer::CompositeSerializer.new({ key: foo }).to_hash
      ).to eq(key: { id: 1, bar: 'bar' })
    end

    context 'custom options' do
      it do
        expect(
          USerializer::CompositeSerializer.new(
            { key: foo },
            serializer: { key: CompositeTesting::FooCustomSerializer },
            root:       { key: :foofoo }
          ).to_hash
        ).to eq(foofoo: { id: 1, bar: 'custom bar' })
      end
    end
  end

  context 'multi objects' do
    it do
      expect(
        USerializer::CompositeSerializer.new(
          { key: foo, key_1: [foo] }
        ).to_hash
      ).to eq(
        key:  { id: 1, bar: 'bar' },
        key_1: [{ id: 1, bar: 'bar' }]
      )
    end

    context 'custom options' do
      it do
        expect(
          USerializer::CompositeSerializer.new(
            { key: foo, key_1: [foo] },
            each_serializer: { key_1: CompositeTesting::FooCustomSerializer },
            root:            { key_1: :foooos, key: :foofoo }
          ).to_hash
        ).to eq(
          foofoo: { id: 1, bar: 'bar' },
          foooos: [{ id: 1, bar: 'custom bar' }]
        )
      end
    end
  end

  context 'with relations' do
    before do
      f_sub = CompositeTesting::Foo.new
      f_sub.id = 3
      f_sub.bar = 'sub_bar'

      foo.bazs = [f_sub]
    end

    it do
      expect(
        USerializer::CompositeSerializer.new(
          { key: foo },
          serializer: { key: CompositeTesting::FooSubSerializer }
        ).to_hash
      ).to(
        eq(
          key:  { id: 1, bar: 'bar', baz_ids: [3] },
          foos: [{ id: 3, bar: 'sub_bar' }]
        )
      )
    end
  end
end
