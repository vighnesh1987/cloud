class AddUserInfoToStorage < ActiveRecord::Migration
  def change
    add_column :storages, :user_id, :int

  end
end
