# Module holding logic that doesn't belong anywhere specifically but that,
# otherwise, would be replicated in different places.
module Utils
  def self.cast(value, klass)
    return value unless value.is_a?(String)

    case
    when klass == Date       then Date.parse(value)
    when klass == BigDecimal then BigDecimal(value)
    else value
    end
  end
end
