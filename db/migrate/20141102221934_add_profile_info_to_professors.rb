class AddProfileInfoToProfessors < ActiveRecord::Migration
  def change
    add_column :professors, :role, :string
    add_column :professors, :department, :string
    add_column :professors, :netid, :string
    add_column :professors, :address, :string
    add_column :professors, :phone, :string
  end
end
