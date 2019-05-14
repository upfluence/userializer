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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/AlexisMontagne/userializer.
