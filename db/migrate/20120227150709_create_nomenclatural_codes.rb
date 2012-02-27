class CreateNomenclaturalCodes < ActiveRecord::Migration
  def change
    create_table :nomenclatural_codes do |t|
      t.string :code
      t.string :title

      t.timestamps
    end
  end
end
