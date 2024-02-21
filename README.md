# Userializer

Ruby object JSON serializer.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'userializer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install userializer

## Usage

USerializer's DSL is relatively close to Active Model Serializer's,
while having a few additional features including:
* Attributes Conditional Declaration
* Attributes Inline Definition

### Attributes Conditional Declaration

USerializer allows you to dynamically decide wether an attribute should
be serialized or not by passing its definition an `if` block as follows:
```ruby
attributes :conditional_attr, if: proc { |_, opts| ... }
```

Eg: Let's say you want to serialize an `Order` object but want to
include its `price` only if it's superior to *10*, your serializer
would look like the following:
```ruby
class Order < ActiveRecord::Base
  def price
    10
  end
end

class OrderSerializer < USerializer::BaseSerializer
  attributes :price, if: proc do |obj, _|
    obj.price > 10
  end
end
```

In that case for example, the `price` attribute would be omitted from
the final response.

### Attributes Inline Definition

Using AMS, the only way to rewrite an attribute prior to serialization
is to override it using a method with the same name, leading to
something like this:
```ruby
class MyObject < ActiveRecord::Base
  def random_attr
    0
  end
end

class MyObjectSerializer < ActiveModel::Serializer
  attributes :random_attr

  def random_attr
    object.random_attr + 1
  end
end
```

While this code works perfectly, it pushes the serialized attribute
value definition back from its declaration, causing developers to lose
focus when listing their serialized attributes because the overriding is
done farther.

With USerializer, all of this is done in an inline way, so that you can
override the attribute's value while declaring using a block as
follows:
```ruby
attributes :your_attribute do |object, _|
  ...
end
```

Our `random_attr` serialization would then looks like this with
USerializer:
```ruby
class MyObjectSerializer < USerializer::BaseSerializer
  attributes :random_attr do |object, _|
    object.random_attr + 1
  end
end
```

Way nicer, right?

### Relationships

Just like AMS, USerializer supports `has_one` and `has_many`
relationships

### Collection Attributes Filtering

For `has_many` relationships, USerializer allow you to serialize only
part of the collection that matches some criterias.
It relies on the ActiveRecord `scope` feature :

```ruby
class Product < ActiveRecord::Base
  has_many :variants
end

class Variant < ActiveRecord::Base
  belongs_to :product

  scope :available, -> { where(delete_at: nil) }
end

class ProductSerializer < USerializer::BaseSerializer
  has_many :variants, scope: :available
end

class VariantSerializer < USerializer::BaseSerializer
end
```

### Serialized Output

The following outputs will be based an on our `Order` object in
different situations:

* Order is serialized without any relationships:
```json
{
  "order": {
    "id": 1,
    "attr_1": "value_1",
    "attr_2": "value_2",
    "attr_3": "value_3",
  }
}
```

* Order has a `has_one` relationship with a `Client` model
```json
{
  "clients": [
    {
      "id": 4,
      "name": "userializer client",
      ...
    }
  ],
  "order": {
    "id": 1,
    "attr_1": "value_1",
    "attr_2": "value_2",
    "attr_3": "value_3",
    "client_id": 4
  }
}
```

* Order has a `has_many` relationship with an `Article` model
```json
{
  "articles": [
    {
      "id": 1,
      "name": "Article #1",
      ...
    },
    {
      "id": 1,
      "name": "Article #2",
      ...
    }
  ],
  "order": {
    "id": 1,
    "attr_1": "value_1",
    "attr_2": "value_2",
    "attr_3": "value_3",
    "article_ids": [1, 2]
  }
}
```

### CompositeSerializer

Imagine you have a compound of different data that you want to return to the same payload.
For example, you have an **array** of a `Foo` class and a `Bar` value to return.
You can use a `CompositeSerializer` to serialize both.

```ruby
array_foo = [Foo.new, Foo.new]
bar = Bar.new

CompositeSerializer.new(
  { key_foo: array_foo, key_bar: bar },
  each_serializer: { key_foo: FooCustomSerializer },
  serializer: { key_bar: BarSerializer },
  root: { key_foo: :foo_root, key_bar: :bar_root }
).to_json
```

this will render:

```json
{
  "foo_root": [{... foo1 attributes ...}, {... foo2 attributes ...}],
  "bar_root": {... bar attributes ...}
}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/AlexisMontagne/userializer.
