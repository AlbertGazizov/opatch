require 'spec_helper'

describe OPatch do

  context "simple fields" do
    before do
      Person = Struct.new(:name)
    end

    it "should patch simple field" do
      person = Person.new('Ivan')

      OPatch.patch(person, name: 'Vasya') do
        field :name
      end

      person.name.should == 'Vasya'
    end

    it "should patch field using given block" do
      person = Person.new('Ivan')

      OPatch.patch(person, name: 'Vasya') do
        field :name, proc { |person, new_name| person.name = new_name }
      end

      person.name.should == 'Vasya'
    end
  end

  context "nested object" do
    before do
      Address = Struct.new(:country, :city)
      Person = Struct.new(:name, :address)
      class Person
        def build_address(attrs)
          self.address = Address.new(attrs[:country], attrs[:city])
        end
      end
    end

    it "should patch nested object fields" do
      person = Person.new('Ivan', Address.new('Russia', 'Kazan'))

      OPatch.patch(person, name: 'Vasya', address: { country: 'USA', city: 'New York'}) do
        field  :name
        object :address do
          field :country
          field :city
        end
      end

      person.address.country.should == 'USA'
      person.address.city.should == 'New York'
    end

    it "should nullify nested object if nil was given" do
      person = Person.new('Ivan', Address.new('Russia', 'Kazan'))

      OPatch.patch(person, name: 'Vasya', address: nil) do
        field  :name
        object :address do
          field :country
          field :city
        end
      end

      person.address.should be_nil
    end

    it "should build nested object if it was nil before" do
      person = Person.new('Ivan')

      OPatch.patch(person, name: 'Vasya', address: { country: 'Russia', city: 'Kazan' }) do
        field  :name
        object :address, build: proc { |person, attributes| person.build_address(attributes) } do
          field :country
          field :city
        end
      end

      person.address.should_not be_nil
      person.address.country.should == 'Russia'
      person.address.city.should == 'Kazan'
    end

    it "should raise error if build block wasn't specified but attributes were given" do
      person = Person.new('Ivan')

      expect do
        OPatch.patch(person, name: 'Vasya', address: { country: 'Russia', city: 'Kazan' }) do
          field  :name
          object :address do
            field :country
            field :city
          end
        end
      end.to raise_error(ArgumentError, "address build block should be specified")
    end

    it "should remove nested object if nil was given" do
      person = Person.new('Ivan')
      person.build_address(counry: 'Russia', city: 'Kazan')

      OPatch.patch(person, name: 'Vasya', address: nil) do
        field  :name
        object :address, remove: proc { |person, attributes| person.address = :removed }
      end

      person.address.should == :removed
    end
  end

  context "nested collection" do
    before do
      Person = Struct.new(:name, :emails)
      Email  = Struct.new(:id, :address, :type)
      class Person
        def build_email(attrs)
          self.emails << Email.new(nil, attrs[:address], attrs[:type])
        end
      end
    end

    it "should patch collection objects" do
      person = Person.new(
        'Ivan',
        [
          Email.new(1, 'work@example.com', :work),
          Email.new(2, 'work2@example.com', :work)
        ]
      )

      attributes = {
        emails: [
          { id: 1, address: 'home@example.com',  type: :home },
          { id: 2, address: 'home2@example.com', type: :home }
        ]
      }
      OPatch.patch(person, attributes) do
        collection :emails, key: :id, build: proc { |person, attrs| person.build_email(attrs) } do
          field :address
          field :type
        end
      end

      person.emails.count.should == 2

      email = person.emails[0]
      email.address.should == 'home@example.com'
      email.type.should == :home

      email = person.emails[1]
      email.address.should == 'home2@example.com'
      email.type.should == :home
    end

    it "should add new object to collection" do
      person = Person.new(
        'Ivan',
        [
          Email.new(1, 'work@example.com', :work),
        ]
      )

      attributes = {
        emails: [
          { address: 'home@example.com', type: :home }
        ]
      }
      OPatch.patch(person, attributes) do
        collection :emails, key: :id, build: proc { |person, attrs| person.build_email(attrs) } do
          field :address
          field :type
        end
      end

      person.emails.count.should == 2

      email = person.emails[0]
      email.address.should == 'work@example.com'
      email.type.should == :work

      email = person.emails[1]
      email.address.should == 'home@example.com'
      email.type.should == :home
    end

    it "should remove collection object if _destroy: true was specified" do
      person = Person.new(
        'Ivan',
        [
          Email.new(1, 'work@example.com', :work),
          Email.new(2, 'work2@example.com', :work)
        ]
      )

      attributes = {
        emails: [
          { id: 2, _destroy: true },
        ]
      }
      OPatch.patch(person, attributes) do
        collection :emails, key: :id, build: proc { |person, attrs| person.build_email(attrs) } do
          field :address
          field :type
        end
      end

      person.emails.count.should == 1
      person.emails.first.id.should == 1
    end

    it "should raise error if non existing key was specified" do

    end

    it "should build new object with key if assign_key is true" do

    end
  end

  it "should raise error if undeclared attributes were specified" do
  end

  context "errors" do
    it "should raise error if non symbol argument was given to the field method" do
      Person = Struct.new(:name)
      person = Person.new('Ivan')

      expect do
        OPatch.patch(person, name: 'Vasya') do
          field 'name'
        end
      end.to raise_error(ArgumentError, "field name should be a symbol")
    end
  end
end
