class CreateIdentities < ActiveRecord::Migration
  def change
    create_table :identities do |t|
      t.string :uid
      t.integer :provider_id
      t.integer :user_id

      t.timestamps
    end
  end
end
