class CreateRequirements < ActiveRecord::Migration
  def change
    create_table :requirements do |t|
      t.string :name
      t.string :min_grade
      t.integer :hours
      t.integer :take
      t.string :type

      t.timestamps null: false
    end
  end
end
