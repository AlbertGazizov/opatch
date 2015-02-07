class OPatch::Patcher
  attr_reader :entity, :attributes

  def initialize(entity, attributes, &block)
    @entity     = entity
    @attributes = attributes
  end

  private :initialize

  def self.patch(entity, attributes, &block)
    new(entity, attributes).instance_exec(&block)
  end

  private

  def field(field_name, block = nil)
    raise ArgumentError, "field name should be a symbol" unless field_name.is_a?(Symbol)
    if attributes.has_key?(field_name)
      value = attributes[field_name]
      if block
        block.call(entity, value)
      else
        entity.send("#{field_name}=", value)
      end
    end
  end

  def object(field_name, options = {}, &block)
    if attributes.has_key?(field_name)
      if attributes[field_name].nil?
        entity.send("#{field_name}=", nil)
      else
        child_entity = entity.send(field_name)
        if child_entity
          self.class.patch(entity.send(field_name), attributes[field_name], &block)
        else
          build_block = options[:build]
          # Todo: ensure block is proc
          raise ArgumentError, "#{field_name} build block should be specified" unless build_block
          build_block.call(entity, attributes[field_name])
        end
      end
    end
  end

  def collection(collection_name, options = {}, &block)
    raise ArgumentError, "#{collection_name} collection key should be specified" unless options[:key]
    raise ArgumentError, "#{collection_name} build block should be specified" unless options[:build]
    # Todo: ensure key is a symbol or array of symbols, block is proc
    key         = options[:key]
    build_block = options[:build]
    if attributes.has_key?(collection_name)
      collection = entity.send(collection_name)
      collection_hash = collection.group_by { |item| object_key_value(item, key) }
      attributes[collection_name].each do |child_attributes|
        key_value = attributes_key_value(child_attributes, key)
        if key_value
          child_object = (collection_hash[key_value] || []).first
          raise "#{collection_name} don't have an object with key: #{key_value}" unless child_object
          if child_attributes[:_destroy]
            collection.delete(child_object)
          else
            self.class.patch(child_object, child_attributes, &block)
          end
        else
          build_block.call(entity, child_attributes)
        end
      end
    end
  end

  def object_key_value(object, key)
    if key.is_a?(Array)
      key.map { |k| object.send(k) }
    else
      object.send(key)
    end
  end

  def attributes_key_value(attributes, key)
    if key.is_a?(Array)
      key.map { |k| attributes[:k] }
    else
      attributes[key]
    end
  end
end
