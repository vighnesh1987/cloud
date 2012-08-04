class RemoveAuthProviderFromAuthentications < ActiveRecord::Migration
  def up
    remove_column :authentications, :auth_provider
      end

  def down
    add_column :authentications, :auth_provider, :string
  end
end
