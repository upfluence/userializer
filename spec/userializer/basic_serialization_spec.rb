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
end

RSpec.describe USerializer::BaseSerializer do
  let(:f) do
    f = Foo.new
    f.id = 1
    f.bar = 'bar'

    f
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
end
