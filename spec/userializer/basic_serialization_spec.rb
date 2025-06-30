require 'spec_helper'

class FooSerializer < USerializer::BaseSerializer
  attributes :bar, :buz

  def buz
    'biz'
  end
end

class FooCustomSerializer < USerializer::BaseSerializer
  attributes :bar do |object, opts|
    "#{object.bar} #{opts[:scope]}"
  end
end

class Foo
  attr_accessor :id, :bar

  attr_accessor :bazs
end

class FooSubSerializer < FooSerializer
  has_many :bazs
end

class FooSkipNilSerializer < USerializer::BaseSerializer
  attributes :bazs
  attributes :bar, skip_nil: true
end

class AttributesRelations
  attr_accessor :id, :relations, :attributes
end

class AttributesRelationsSerializer < USerializer::BaseSerializer
  attributes :relations, :attributes
end

RSpec.describe USerializer::BaseSerializer do
  let(:f) do
    f = Foo.new
    f.id = 1
    f.bar = 'bar'

    f
  end

  context 'does not carry inherited fields' do
    it do
      expect(FooSerializer.new(f).to_hash).to eq(
        foo: { id: 1, bar: 'bar', buz: 'biz' }
      )
    end

    it do
      expect(FooSubSerializer.new(f).to_hash).to eq(
        foo: { id: 1, bar: 'bar', buz: 'biz', baz_ids: [] }
      )
    end
  end

  context 'custom attribute' do
    it do
      expect(FooCustomSerializer.new(f, scope: 'buz').to_hash).to eq(
        foo: { id: 1, bar: 'bar buz' }
      )
    end
  end

  context 'carry the correct values' do
    it do
      expect(FooSerializer.new(f).to_hash).to eq(
        foo: { id: 1, bar: 'bar', buz: 'biz' }
      )
    end
  end

  context 'handle root option' do
    it do
      expect(FooSerializer.new(f, root: 'buz').to_hash).to eq(
        buz: { id: 1, bar: 'bar', buz: 'biz' }
      )
    end
  end

  context 'handle meta' do
    it do
      expect(FooSerializer.new(f, meta: { foo: 'bar' }).to_hash).to eq(
        foo: { id: 1, bar: 'bar', buz: 'biz' }, meta: { foo: 'bar' }
      )
    end
  end

  context 'except' do
    it do
      expect(FooSerializer.new(f, except: %i[bar buz]).to_hash).to eq(
        foo: { id: 1 }
      )
    end
  end

  context 'only' do
    it do
      expect(FooSerializer.new(f, only: %i[buz]).to_hash).to eq(
        foo: { buz: 'biz' }
      )
    end
  end

  context 'only && except' do
    it do
      expect(FooSerializer.new(
        f, only: %i[buz], except: %i[buz]
      ).to_hash).to eq(foo: { buz: 'biz' })
    end
  end

  context 'skip nil' do
    let(:f) do
      f = Foo.new
      f.id = 1
      f
    end

    it do
      expect(FooSkipNilSerializer.new(f).to_hash).to eq(
        foo: { id: 1, bazs: nil }
      )
    end
  end

  context 'attributes && relations' do
    let(:f) do
      f = AttributesRelations.new
      f.id = 1
      f.attributes = 'foo'
      f.relations = 'bar'
      f
    end

    it do
      expect(AttributesRelationsSerializer.new(f).to_hash).to eq(
        attributes_relations: {
          id:         1,
          attributes: 'foo',
          relations:  'bar'
        }
      )
    end
  end
end
