require_relative '03_associatable'
require 'byebug'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    through_options = assoc_options[through_name]
    debugger
    define_method(name) do
      source_options = assoc_options[source_name]

      through_options.class_name

    end
  end
end
