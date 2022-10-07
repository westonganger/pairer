module Pairer
  class Config

    @@allowed_org_ids = []
    mattr_reader :allowed_org_ids

    def self.allowed_org_ids=(val)
      if val.is_a?(Array)
        @@allowed_org_ids = val.collect(&:presence).compact
      else
        raise "Must be an array"
      end
    end

    @@hash_id_salt = true
    mattr_reader :hash_id_salt

    def self.hash_id_salt=(val)
      if val.is_a?(String)
        @@hash_id_salt = val
      else
        raise ArgumentError.new("hash_id_salt must be String")
      end
    end

    @@max_iterations_to_track = 100
    mattr_reader :max_iterations_to_track

    def self.max_iterations_to_track=(val)
      if val.is_a?(Integer) && val >= 1
        @@max_iterations_to_track = val
      else
        raise "Must be a positive integer"
      end
    end

  end
end
