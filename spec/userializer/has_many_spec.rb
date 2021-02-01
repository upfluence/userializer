require 'spec_helper'

module HasManyTesting
  class Collection < Array
    def evens
      select { |i| i.id.even? }
    end
  end

  class FooSerializer < USerializer::BaseSerializer
    attributes :bar
  end

  class EmptySerializer < USerializer::BaseSerializer
  end

  class Foo
    attr_accessor :id, :bar
  end

  class BarSerializer < USerializer::BaseSerializer
    has_many :foos
  end

  class BarScopedSerializer < USerializer::BaseSerializer
    has_many :foos, scope: :evens
  end

  class BarProcSerializer < USerializer::BaseSerializer
    CUSTOM_SERIALIZER = Proc.new do |_, opts|
      opts[:scope].eql?(:none) ? EmptySerializer : FooSerializer
    end

    has_many :foos, each_serializer: CUSTOM_SERIALIZER
  end

  class Bar
    attr_accessor :id, :foos
  end
end

RSpec.describe USerializer::BaseSerializer do
  context 'empty relation' do
    it do
      b = HasManyTesting::Bar.new
      b.id = 2
      expect(
        HasManyTesting::BarSerializer.new(b).to_hash
      ).to eq(bar: { id: 2, foo_ids: [] })
    end
  end

  context 'relation' do
    it do
      f = HasManyTesting::Foo.new
      f.bar = 'bar'
      f.id = 1

      b = HasManyTesting::Bar.new
      b.foos = [f]
      b.id = 2

      expect(HasManyTesting::BarSerializer.new(b).to_hash).to eq(
        bar: { id: 2, foo_ids: [1] }, foos: [id: 1, bar: 'bar']
      )
    end
  end

  context 'has proc serializer' do
    let(:b) do
      f = HasManyTesting::Foo.new
      f.bar = 'bar'
      f.id = 1

      b = HasManyTesting::Bar.new
      b.foos = [f]
      b.id = 2

      b
    end

    it do
      expect(
        HasManyTesting::BarProcSerializer.new(b, scope: :other).to_hash
      ).to eq(bar: { id: 2, foo_ids: [1] }, foos: [{ id: 1, bar: 'bar' }])
    end

    it do
      expect(
        HasManyTesting::BarProcSerializer.new(b, scope: :none).to_hash
      ).to eq(bar: { id: 2, foo_ids: [1] }, foos: [{ id: 1 }])
    end
  end

  context 'has a scope' do
    it do
      f1 = HasManyTesting::Foo.new
      f1.bar = 'bar'
      f1.id = 1

      f2 = HasManyTesting::Foo.new
      f2.bar = 'bar bar'
      f2.id = 2

      b = HasManyTesting::Bar.new
      b.foos = HasManyTesting::Collection.new([f1, f2])
      b.id = 2

      expect(HasManyTesting::BarScopedSerializer.new(b).to_hash).to eq(
        bar: { id: 2, foo_ids: [2] }, foos: [id: 2, bar: 'bar bar']
      )
    end
  end
end
