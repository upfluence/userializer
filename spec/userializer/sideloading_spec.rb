require 'spec_helper'

module SideloadingTesting
  class Collection < Array
    attr_reader :scope_calls

    def initialize(*)
      super
      @scope_calls = 0
    end

    def available
      @scope_calls += 1
      self
    end
  end

  class Tag
    attr_accessor :id, :name

    def initialize(id, name = nil)
      @id = id
      @name = name
    end
  end

  class TagSerializer < USerializer::BaseSerializer
    attributes :name
  end

  class Post
    attr_accessor :id, :tags, :main_tag

    def initialize(id, tags, main_tag = nil)
      @id = id
      @tags = tags
      @main_tag = main_tag
    end
  end

  class PostSerializer < USerializer::BaseSerializer
    has_many :tags, scope: :available
    has_one :main_tag, root: :tags
  end

  class PostConditionalSerializer < USerializer::BaseSerializer
    has_many :tags, if: proc { false }
    has_one :main_tag, if: proc { false }
  end
end

RSpec.describe USerializer::BaseSerializer do
  def tags(*ids)
    SideloadingTesting::Collection.new(
      ids.map { |id| SideloadingTesting::Tag.new(id, "tag #{id}") }
    )
  end

  context 'deduplicates sideloaded entities across parents' do
    it do
      posts = [
        SideloadingTesting::Post.new(1, tags(1, 2), tags(2).first),
        SideloadingTesting::Post.new(2, tags(2, 3), tags(4).first)
      ]

      expect(USerializer::ArraySerializer.new(posts).to_hash).to eq(
        posts: [
          { id: 1, tag_ids: [1, 2], main_tag_id: 2 },
          { id: 2, tag_ids: [2, 3], main_tag_id: 4 }
        ],
        tags:  [
          { id: 1, name: 'tag 1' },
          { id: 2, name: 'tag 2' },
          { id: 3, name: 'tag 3' },
          { id: 4, name: 'tag 4' }
        ]
      )
    end
  end

  context 'does not deduplicate entities without id' do
    it do
      objs = [
        SideloadingTesting::Tag.new(nil, 'a'),
        SideloadingTesting::Tag.new(nil, 'b')
      ]

      expect(USerializer::ArraySerializer.new(objs).to_hash).to eq(
        tags: [{ id: nil, name: 'a' }, { id: nil, name: 'b' }]
      )
    end
  end

  context 'returns a plain hash' do
    it do
      post = SideloadingTesting::Post.new(1, tags(1))

      expect(
        SideloadingTesting::PostSerializer.new(post).to_hash.class
      ).to eq(Hash)
    end
  end

  context 'evaluates the has_many scope once' do
    it do
      collection = tags(1, 2)
      post = SideloadingTesting::Post.new(1, collection)

      SideloadingTesting::PostSerializer.new(post).to_hash

      expect(collection.scope_calls).to eq(1)
    end
  end

  context 'does not load relations when the condition is false' do
    it do
      post = SideloadingTesting::Post.new(1, nil)

      allow(post).to receive(:tags).and_raise('tags loaded')
      allow(post).to receive(:main_tag).and_raise('main_tag loaded')

      expect(
        SideloadingTesting::PostConditionalSerializer.new(post).to_hash
      ).to eq(post: { id: 1 })
    end
  end
end
