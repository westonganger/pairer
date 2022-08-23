module Pairer
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    after_create do
      salt = "51mA!p9LGLQC"
      self.update_columns(public_id: Hashids.new(salt, 8).encode(id))
    end

    validates :public_id, uniqueness: {case_sensitive: true, allow_blank: true}

    def to_param
      try(:public_id) || id
    end

  end
end
