require "pairer/engine"

module Pairer

  @@allowed_org_names = []

  mattr_reader :allowed_org_names

  def self.allowed_org_names=(val)
    if val.is_a?(Array)
      @@allowed_org_names = val.collect(&:presence).compact
    else
      raise "Must be an array"
    end
  end

end
