module Pairer
  class Group < ApplicationRecord
    belongs_to :board, class_name: "Pairer::Board"

    validates :board_id, presence: true
    validates :board_iteration_number, presence: true, numericality: { only_integer: true, minimum: 0 }

    def person_ids=(val)
      if val.is_a?(Array)
        sanitized_array = val.map{|x| x.presence&.strip }.uniq(&:downcase).compact

        if !new_record?
          sanitized_array = sanitized_array.intersection(board.people.map(&:public_id)) ### This may slow the query down
        end

        self[:person_ids] = sanitized_array.join(";;")
      else
        raise "invalid behaviour"
      end
    end

    def person_ids_array
      self[:person_ids]&.split(";;") || []
    end

    def roles=(val)
      if val.is_a?(Array)
        sanitized_array = self[:roles] = val.map{|x| x.presence&.strip }.uniq(&:downcase).compact

        if !new_record?
          sanitized_array = sanitized_array.intersection(board.roles_array) ### This may slow the query down
        end

        self[:roles] = sanitized_array.join(";;")
      else
        raise "invalid behaviour"
      end
    end

    def roles_array
      self[:roles]&.split(";;") || []
    end

  end
end
