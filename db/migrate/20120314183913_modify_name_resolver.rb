class ModifyNameResolver < ActiveRecord::Migration
  def up
    execute "alter table name_resolvers modify data longtext"
  end

  def down
    execute "alter table name_resolvers modify data text"
  end
end
