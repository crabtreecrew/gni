class AddFieldsToNameResolvers < ActiveRecord::Migration
  def up
    execute "alter table name_resolvers add column response longtext"
    add_column :name_resolvers, :token, :string, :nil => false
    add_index :name_resolvers, [:token], :unique => true
  end

  def down
    remove_column :name_resolvers, :token
    remove_column :name_resolvers, :response
  end
end
