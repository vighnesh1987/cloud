class CreateAuthentications < ActiveRecord::Migration
  def change
    create_table :authentications do |t|
      t.integer :user_id
      t.string :auth_provider   # 'facebook', 'twitter', etc
      t.string :auth_id         # user's id in facebook/twitter
      t.timestamps
    end
  end
end

