class RenameExternalListReconciler < ActiveRecord::Migration
  def up
    execute "rename table external_list_reconcilers to name_resolvers"
  end

  def down
    execute "rename table name_resolvers to external_list_reconcilers"
  end
end
