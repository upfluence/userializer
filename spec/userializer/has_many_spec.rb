require 'spec_helper'

module HasManyTesting
  class FooSerializer < USerializer::BaseSerializer
    attributes :bar
  end

  class Foo
    attr_accessor :id, :bar
  end

  class BarSerializer < USerializer::BaseSerializer
    has_many :foos
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
end
