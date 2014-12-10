class CreateSections < ActiveRecord::Migration
  def change
    create_table :sections do |t|
      t.integer :crn
      t.string :term
      t.belongs_to :professor
      t.belongs_to :course

      t.timestamps
    end
  end
end
