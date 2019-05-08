require 'spec_helper'

module HasOneTesting
  class FooSerializer < USerializer::BaseSerializer
    attributes :bar
  end

  class Foo
    attr_accessor :id, :bar, :biz
  end

  class FooCustomSerializer < USerializer::BaseSerializer
    attributes :buz

    def buz
      'zzz'
    end
  end

  class BarSerializer < USerializer::BaseSerializer
    has_one :foo
  end

  class Bar
    attr_accessor :id, :foo
  end

  class BarCustomSerializer < USerializer::BaseSerializer
    has_one :foo, serializer: FooCustomSerializer
  end

  class BarExceptSerializer < USerializer::BaseSerializer
    has_one :foo, serializer: FooCustomSerializer, except: :buz
  end

  class FooNestedSerializer < USerializer::BaseSerializer
    has_one :biz
  end

  class BarNestedSerializer < USerializer::BaseSerializer
    has_one :foo, serializer: FooNestedSerializer
  end

  class Biz
    attr_accessor :id
  end

  class BizSerializer < USerializer::BaseSerializer
    attributes :zaz

    def zaz
      "zaz"
    end
  end
end

RSpec.describe USerializer::BaseSerializer do
  let(:b) do
    f = HasOneTesting::Foo.new
    f.id = 1
    f.bar = 'bar'

    b = HasOneTesting::Bar.new
    b.foo = f
    b.id = 2

    b
  end

  context 'empty relation' do
    it do
      c = HasOneTesting::Bar.new
      c.id = 2
      expect(
        HasOneTesting::BarSerializer.new(c).to_hash
      ).to eq(bar: { id: 2, foo_id: nil })
    end
  end

  context 'relation' do
    it do
      expect(HasOneTesting::BarSerializer.new(b).to_hash).to eq(
        bar: { id: 2, foo_id: 1 }, foos: [id: 1, bar: 'bar']
      )
    end
  end

  context 'custom' do
    it do
      expect(HasOneTesting::BarCustomSerializer.new(b).to_hash).to eq(
        bar: { id: 2, foo_id: 1 }, foos: [id: 1, buz: 'zzz']
      )
    end
  end

  context 'except' do
    it do
      expect(HasOneTesting::BarExceptSerializer.new(b).to_hash).to eq(
        bar: { id: 2, foo_id: 1 }, foos: [id: 1]
      )
    end
  end

  context 'nested' do
    it do
      n = HasOneTesting::Bar.new
      n.id = 2
      n.foo = HasOneTesting::Foo.new
      n.foo.id = 42
      n.foo.biz = HasOneTesting::Biz.new
      n.foo.biz.id = 27
      expect(HasOneTesting::BarNestedSerializer.new(n).to_hash).to eq(
        bar: { id: 2, foo_id: 42 },
        foos: [id: 42, biz_id: 27],
        bizs: [id: 27, zaz: 'zaz']
      )
    end
  end
end
