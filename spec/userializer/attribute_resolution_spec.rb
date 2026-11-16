require 'spec_helper'

module AttributeResolutionTesting
  class Post
    attr_accessor :id, :meta, :opts, :obj, :object, :hash, :format, :title,
                  :author

    def initialize(opts = {})
      opts.each { |k, v| send("#{k}=", v) }
    end
  end

  class Author
    attr_accessor :id
  end

  class AuthorSerializer < USerializer::BaseSerializer
  end

  class PostSerializer < USerializer::BaseSerializer
    attributes :meta, :opts, :obj, :object, :hash, :format
  end

  module Titleize
    def title
      object.title.upcase
    end
  end

  class PostTitleSerializer < USerializer::BaseSerializer
    include Titleize

    attributes :title
  end

  class PostTitleChildSerializer < PostTitleSerializer
  end

  module NestedTitleize
    include Titleize
  end

  class PostNestedModuleSerializer < USerializer::BaseSerializer
    include NestedTitleize

    attributes :title
  end

  class PostDefineMethodSerializer < USerializer::BaseSerializer
    attributes :title

    define_method(:title) { "defined #{object.title}" }
  end

  class PostPrivateSerializer < USerializer::BaseSerializer
    attributes :title

    private

    def title
      "private #{object.title}"
    end
  end

  class PostRelationSerializer < USerializer::BaseSerializer
    has_one :meta, serializer: AuthorSerializer, root: :authors
  end
end

RSpec.describe USerializer::BaseSerializer do
  let(:post) do
    AttributeResolutionTesting::Post.new(
      id:     1,
      meta:   'post meta',
      opts:   'post opts',
      obj:    'post obj',
      object: 'post object',
      hash:   'post hash',
      format: 'post format',
      title:  'title'
    )
  end

  context 'attribute named like a serializer or Kernel method' do
    it do
      expect(
        AttributeResolutionTesting::PostSerializer.new(
          post, meta: { page: 1 }
        ).to_hash
      ).to eq(
        post: {
          id:     1,
          meta:   'post meta',
          opts:   'post opts',
          obj:    'post obj',
          object: 'post object',
          hash:   'post hash',
          format: 'post format'
        },
        meta: { page: 1 }
      )
    end
  end

  context 'method defined in an included module' do
    it do
      expect(
        AttributeResolutionTesting::PostTitleSerializer.new(post).to_hash
      ).to eq(post: { id: 1, title: 'TITLE' })
    end
  end

  context 'method defined in a parent serializer' do
    it do
      expect(
        AttributeResolutionTesting::PostTitleChildSerializer.new(post).to_hash
      ).to eq(post: { id: 1, title: 'TITLE' })
    end
  end

  context 'method defined in a nested included module' do
    it do
      expect(
        AttributeResolutionTesting::PostNestedModuleSerializer.new(post).to_hash
      ).to eq(post: { id: 1, title: 'TITLE' })
    end
  end

  context 'method defined with define_method' do
    it do
      expect(
        AttributeResolutionTesting::PostDefineMethodSerializer.new(post).to_hash
      ).to eq(post: { id: 1, title: 'defined title' })
    end
  end

  context 'private serializer method' do
    it do
      expect(
        AttributeResolutionTesting::PostPrivateSerializer.new(post).to_hash
      ).to eq(post: { id: 1, title: 'private title' })
    end
  end

  context 'relation named like a serializer method' do
    it do
      author = AttributeResolutionTesting::Author.new
      author.id = 7
      post.meta = author

      expect(
        AttributeResolutionTesting::PostRelationSerializer.new(post).to_hash
      ).to eq(post: { id: 1, meta_id: 7 }, authors: [{ id: 7 }])
    end
  end
end
