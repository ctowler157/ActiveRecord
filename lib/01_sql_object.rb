require_relative 'db_connection'
require 'active_support/inflector'
# require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.columns
    return @columns if @columns

    columns = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL

    @columns = columns.first.map(&:to_sym)
  end

  def self.finalize!
    columns.each do |attribute|
      define_method(attribute) do
        attributes[attribute]
      end

      define_method("#{attribute}=") do |value|
        attributes[attribute] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
    SQL

      parse_all(results)
  end

  def self.parse_all(results)
    results.map do |hash|
      self.new(hash)
    end
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        #{table_name}.id = ?
    SQL
      return nil if results.empty?

      new(results.first)
  end

  def initialize(params = {})
    params.each do |attribute, value|
      unless self.class.columns.include?(attribute.to_sym)
        raise ("unknown attribute '#{attribute}'")
      end

      send("#{attribute}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    cols.map do |attribute|
      send(attribute)
    end
  end

  def cols
    self.class.columns
  end

  def table_name
    self.class.table_name
  end

  def insert
    col_names = cols.join(', ')
    question_marks = Array.new(cols.count) { "?" }.join(', ')

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    send(:id=, DBConnection.last_insert_row_id)
  end

  def update
    values_string = cols
                      .map { |col| "#{col} = ?" }
                      .join(", ")

    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{table_name}
      SET
        #{values_string}
      WHERE
        id = ?
    SQL
  end

  def save
    if id.nil?
      insert
    else
      update
    end
  end
end
