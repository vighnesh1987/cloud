class CreateStorages < ActiveRecord::Migration
  def change
    create_table :storages do |t|
      t.string :uid
      t.string :auth_token

      t.timestamps
    end
  end
end
