module Pairer
  class Person < ApplicationRecord
    belongs_to :board, class_name: "Pairer::Board"

    validates :name, presence: true, uniqueness: {scope: :board_id}
  end
end
