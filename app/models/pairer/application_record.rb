module Pairer
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    after_create do
      salt = Pairer.config.hash_id_salt
      pepper = self.class.table_name

      self.update_columns(public_id: Hashids.new("#{salt}_#{pepper}", 8).encode(id))
    end

    validates :public_id, uniqueness: {case_sensitive: true, allow_blank: true}

    def to_param
      try(:public_id) || id
    end

    if Rails::VERSION::STRING.to_f < 7
      def in_order_of(column, order_array)
        Arel.sql(
          <<~SQL
            case #{table_name}.#{column}
            #{order_array.map_with_index{|x, i| "when '#{x}' then #{i+1}"}.join(" ")}
            else #{order_array.size+1}
            end
          SQL
        )
      end
    end

  end
end
