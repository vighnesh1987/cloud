class RemoveAuthIdFromAuthentications < ActiveRecord::Migration
  def up
    remove_column :authentications, :auth_id
      end

  def down
    add_column :authentications, :auth_id, :string
  end
end
