class AddUserIdToStorage < ActiveRecord::Migration
  def change
    add_column :storages, :user_id, :string

  end
end
