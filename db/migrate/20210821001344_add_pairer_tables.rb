class AddPairerTables < ActiveRecord::Migration[6.0]
  def change

    create_table :pairer_boards do |t|
      t.string :name, :password
      t.text :roles
      t.integer :current_iteration_number, null: false
      t.integer :group_size
      t.integer :num_iterations_to_track, null: false
      t.timestamps
      t.string :public_id, index: true
      t.string :org_name
    end

    create_table :pairer_people do |t|
      t.references :board
      t.string :name
      t.timestamps
      t.boolean :locked, default: false, null: false
      t.string :public_id, index: true
    end

    create_table :pairer_groups do |t|
      t.references :board
      t.integer :board_iteration_number
      t.timestamps
      t.boolean :locked, default: false, null: false
      t.text :person_ids
      t.text :roles
      t.string :public_id, index: true
    end

  end
end
