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

    def initialize(opts = {})
      @id = opts[:id]
      @bar = opts[:bar]
    end
  end

  class BarSerializer < USerializer::BaseSerializer
    has_many :foos
  end

  class BarScopedSerializer < USerializer::BaseSerializer
    has_many :foos, scope: :evens
  end

  class BarIDsKeySerializer < USerializer::BaseSerializer
    has_many :foos, ids_key: :foobar_ids
  end

  class BarProcSerializer < USerializer::BaseSerializer
    CUSTOM_SERIALIZER = proc do |_, opts|
      opts[:scope].eql?(:none) ? EmptySerializer : FooSerializer
    end

    has_many :foos, each_serializer: CUSTOM_SERIALIZER
  end

  class Bar
    attr_accessor :id, :foos

    def initialize(opts = {})
      @id = opts[:id]
      @foos = opts[:foos]
    end
  end

  class Buz
    attr_accessor :id, :foos

    def initialize(opts = {})
      @id = opts[:id]
      @foos = opts[:foos]
    end
  end

  class BuzSerializer < USerializer::BaseSerializer
    has_many :foos, root: 'foos'
  end

  class Fiz
    attr_accessor :id, :bar, :buz

    def initialize(opts = {})
      @id = opts[:id]
      @bar = opts[:bar]
      @buz = opts[:buz]
    end
  end

  class FizSerializer < USerializer::BaseSerializer
    has_one :bar
    has_one :buz
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

      b = HasManyTesting::Bar.new(
        id:   2,
        foos: HasManyTesting::Collection.new([f1, f2])
      )


      expect(HasManyTesting::BarScopedSerializer.new(b).to_hash).to eq(
        bar: { id: 2, foo_ids: [2] }, foos: [id: 2, bar: 'bar bar']
      )
    end
  end

  context 'has an ids_key' do
    let(:bar) do
      f1 = HasManyTesting::Foo.new(id: 1)
      f2 = HasManyTesting::Foo.new(id: 2)

      HasManyTesting::Bar.new(
        id:   2,
        foos: HasManyTesting::Collection.new([f1, f2])
      )
    end

    it do
      expect(HasManyTesting::BarIDsKeySerializer.new(bar).to_hash).to eq(
        bar:  { id: 2, foobar_ids: [1, 2] },
        foos: [{ id: 1, bar: nil }, { id: 2, bar: nil }]
      )
    end
  end

  context 'has multiple root value class' do
    it do
      fiz = HasManyTesting::Fiz.new(
        id:  1,
        bar: HasManyTesting::Bar.new(
          id: 2, foos: [HasManyTesting::Foo.new(id: 4, bar: '4')]
        ),
        buz: HasManyTesting::Buz.new(
          id: 3, foos: [HasManyTesting::Foo.new(id: 5, bar: '5')]
        )
      )

      expect(HasManyTesting::FizSerializer.new(fiz).to_hash).to eq(
        fiz:  { id: 1, bar_id: 2, buz_id: 3 },
        bars: [{ id: 2, foo_ids: [4] }],
        buzs: [{ id: 3, foo_ids: [5] }],
        foos: [{ id: 4, bar: '4' }, { id: 5, bar: '5' }]
      )
    end
  end
end
