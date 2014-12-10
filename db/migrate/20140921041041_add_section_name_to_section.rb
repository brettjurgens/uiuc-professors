class AddSectionNameToSection < ActiveRecord::Migration
  def change
    add_column :sections, :section_name, :string
  end
end
