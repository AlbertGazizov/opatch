# OPatch [![Build Status](https://travis-ci.org/AlbertGazizov/opatch.png)](https://travis-ci.org/AlbertGazizov/opatch) [![Code Climate](https://codeclimate.com/github/AlbertGazizov/opatch.png)](https://codeclimate.com/github/AlbertGazizov/opatch)



OPatch is ruby objects patcher in declarative way. By providing simple DSL it allows you write complex patch logic with ease

## Usage
Let's say you have the folowing plain ruby classes:
```ruby
  class Person
    attr_accessor :name, :address

    def initialize(name:, address: nil)
      @name = name
      @address = address
    end
  end

  class Address
    attr_accessor :city, :country

    def initialize(city:, country:)
      @city = city
      @country = country
    end
  end
```
And you have the following instance of the Person class:
```ruby
  person = Person.new(name: "John Smith", address: Address.new(city: "Kazan", country: "Russia"))
```
Now you want to update person's name and address fields, let's use OPatch for that.
You need to call OPatch with attributes you want to update:
```ruby
  new_attributes = { name: "Jim White", address: { country: "USA", city: "New York" } }
  OPatch.patch(person, new_attributes) do
    field  :name
    object :address do
      field :country
      field :city
    end
  end
```
That's all! Now you have the person updated:
```ruby
  => #<Person:0x007f8bc42487c0 @name="Jim White", @address=#<Address:0x007f8bc4248838 @city="New York", @country="USA">>
```

### Creating nested objects
Opatch allows you to build nested objects if you specify build block.
Lets see how it works if we want to build address when it wasn't created initialilly:
```ruby
  person = Person.new(name: "John Smith")
  => #<Person:0x007f8bc40239e0 @name="John Smith", @address=nil>
```
```ruby
  new_attributes = { address: { country: "USA", city: "New York" } }
  OPatch.patch(person, new_attributes) do
    field  :name
    object :address, build: proc { |person, attributes| person.address = Address.new(attributes) }  do
      field :country
      field :city
    end
  end
```
```ruby
  => #<Person:0x007f8bc4130590 @name="John Smith", @address=#<Address:0x007f8bc4049a28 @city="New York", @country="USA">>
```


### Deleting nested objects
If you provide nil for the nested object the object will be removed:
```ruby
  person = Person.new(name: "John Smith", address: Address.new(city: "Kazan", country: "Russia"))

  OPatch.patch(person, name: 'Vasya', address: nil) do
    field  :name
    object :address do
      field :country
      field :city
    end
  end

  => #<Person:0x007f8bc400a850 @name="Vasya", @address=nil>
```

### Author
Albert Gazizov, [@deeper4k](https://twitter.com/deeper4k)

