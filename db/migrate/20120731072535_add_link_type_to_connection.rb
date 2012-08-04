class AddLinkTypeToConnection < ActiveRecord::Migration
  def change
    add_column :connections, :link_type, :string

  end
end
