module Util
  # Convert a CamelCaseString to an underscore_string.
  def self.underscore(str)
    str.split(/::/).last.
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
  end
end
