class CreateConnections < ActiveRecord::Migration
  def change
    create_table :connections do |t|
      t.integer :id1
      t.integer :id2
      t.string :type

      t.timestamps
    end
  end
end
