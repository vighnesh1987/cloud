class CreateListings < ActiveRecord::Migration
  def change
    create_table :listings do |t|
      t.integer :user_id
      t.string  :randomized_id
      t.string  :title
      t.string  :category
      t.text    :body
      t.string  :url
      t.string  :embedded_trust_url

      t.timestamps
    end
  end
end

