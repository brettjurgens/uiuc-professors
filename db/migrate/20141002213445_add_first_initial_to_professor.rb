class AddFirstInitialToProfessor < ActiveRecord::Migration
  def change
    add_column :professors, :first_initial, :string
  end
end