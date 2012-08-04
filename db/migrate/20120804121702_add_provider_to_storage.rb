class AddProviderToStorage < ActiveRecord::Migration
  def change
    add_column :storages, :provider, :string

  end
end
