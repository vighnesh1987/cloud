class AddIdentityIdToAuthentications < ActiveRecord::Migration
  def change
    add_column :authentications, :identity_id, :integer

  end
end
