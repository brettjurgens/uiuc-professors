class AddTooVagueNameToProfessors < ActiveRecord::Migration
  def change
    add_column :professors, :name_too_vague, :boolean, default: false
  end
end
