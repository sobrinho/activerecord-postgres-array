class String
  def to_postgres_array
    self
  end

  # Validates the array format. Valid formats are:
  # * An empty string
  # * A string like '{10000, 10000, 10000, 10000}'
  # * TODO A multi dimensional array string like '{{"meeting", "lunch"}, {"training", "presentation"}}'
  def valid_postgres_array?
    string_regexp = /[^",\\]+/
    quoted_string_regexp = /"[^"\\]*(?:\\.[^"\\]*)*"/
    number_regexp = /[-+]?[0-9]*\.?[0-9]+/
    validation_regexp = /\{\s*((#{number_regexp}|#{quoted_string_regexp}|#{string_regexp})(\s*\,\s*(#{number_regexp}|#{quoted_string_regexp}|#{string_regexp}))*)?\}/
    !!match(/^\s*('#{validation_regexp}'|#{validation_regexp})?\s*$/)
  end

  # Creates an array from a postgres array string that postgresql spits out.
  def from_postgres_array(base_type = :string)
    if empty?
      []
    else
      converter = case base_type
                  when :decimal then Proc.new {|x| x.to_d }
                  when :float then Proc.new {|x| x.to_f }
                  when :integer, :bigint then Proc.new {|x| x.to_i }
                  when :timestamp then Proc.new {|x| x.to_time.in_time_zone }
                  else Proc.new {|x| x }
                  end

      parser = ActiveRecordPostgresArray::Parser.new(self, converter)
      parser.parse
    end
  end
end
