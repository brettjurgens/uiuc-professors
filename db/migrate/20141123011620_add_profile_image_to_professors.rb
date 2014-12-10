class AddProfileImageToProfessors < ActiveRecord::Migration
  def change
    add_column :professors, :image_url, :string
  end
end
