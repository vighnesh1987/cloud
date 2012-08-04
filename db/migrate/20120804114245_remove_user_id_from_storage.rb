class RemoveUserIdFromStorage < ActiveRecord::Migration
  def up
    remove_column :storages, :user_id
      end

  def down
    add_column :storages, :user_id, :string
  end
end
