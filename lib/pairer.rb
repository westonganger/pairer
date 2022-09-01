require "pairer/engine"

module Pairer

  @@allowed_org_ids = []

  mattr_reader :allowed_org_ids

  def self.allowed_org_ids=(val)
    if val.is_a?(Array)
      @@allowed_org_ids = val.collect(&:presence).compact
    else
      raise "Must be an array"
    end
  end

end
