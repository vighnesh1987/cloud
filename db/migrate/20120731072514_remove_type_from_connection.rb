class RemoveTypeFromConnection < ActiveRecord::Migration
  def up
    remove_column :connections, :type
      end

  def down
    add_column :connections, :type, :string
  end
end
