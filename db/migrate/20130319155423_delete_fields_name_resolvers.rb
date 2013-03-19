class DeleteFieldsNameResolvers < ActiveRecord::Migration
  def up
    remove_column :name_resolvers, :data
    remove_column :name_resolvers, :result
  end

  def down
    add_column :name_resolvers, :data, :text
    add_column :name_resolvers, :result, :text
  end
end
