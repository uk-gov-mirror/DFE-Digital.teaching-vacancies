class DateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil?

    Date.new(value[1], value[2], value[3])
  rescue Date::Error, TypeError
    record.errors.add(attribute, :invalid)
  end
end
