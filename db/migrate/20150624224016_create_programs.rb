class CreatePrograms < ActiveRecord::Migration
  def change
    create_table :programs do |t|
      t.string :name
      t.references :requirement, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
