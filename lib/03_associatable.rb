require_relative '02_searchable'
require 'active_support/inflector'
require 'byebug'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})

    options = {
      foreign_key: "#{name.to_s.underscore}_id".to_sym,
      class_name: name.to_s.camelcase,
      primary_key: :id
    }.merge(options)

    options.each { |key, value| send("#{key}=", value) }
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    options = {
      foreign_key: "#{self_class_name.to_s.underscore}_id".to_sym,
      class_name: name.to_s.camelcase.singularize,
      primary_key: :id.to_sym
    }.merge(options)

    options.each { |key, value| send("#{key}=", value) }
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)

    define_method(name) do
      key = send(options.send(:foreign_key))
      target_class = options.send(:model_class)
      target_class.send(:where, id: key).first
    end

  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)

    define_method(name) do
      key = send(options.send(:primary_key))
      target_class = options.send(:model_class)
      conditions = { options.foreign_key => key }
      target_class.send(:where, conditions)
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  extend Associatable
end
