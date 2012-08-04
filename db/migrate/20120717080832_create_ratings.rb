class CreateRatings < ActiveRecord::Migration
  def change
    create_table :ratings do |t|
      t.integer :listing_id
      t.integer :stars
      t.integer :rater_id
      t.text :rater_comment

      t.timestamps
    end
  end
end
