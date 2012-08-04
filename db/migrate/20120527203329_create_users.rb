class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string  :first_name
      t.string  :last_name
      # Trust score
      t.integer :trust_score
      # Password/Login
      t.string  :email
      t.string  :login
      t.string  :password_digest
      t.integer :salt

      t.timestamps
    end
  end
end

