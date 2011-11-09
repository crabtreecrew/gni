class CreateDwcaImporters < ActiveRecord::Migration
  def change
    create_table :dwca_importers do |t|
      t.references :data_source
      t.string :url

      t.timestamps
    end
    add_index :dwca_importers, :data_source_id
  end
end
