class UpdateCodesNameStringIndices < ActiveRecord::Migration
  def up
    data = [
      ['animalia', 1],
      ['plantae', 2],
      ['fungi', 2],
      ['algae', 2],
      ['bacteria', 4],
      ['archea', 4]
    ]
    data.each do |name, code_id|
      puts "updating for #{name}"
      execute "update name_string_indices set nomenclatural_code_id = %s where classification_path like '%s|%%' or classification_path rlike '\\\\|%s\\\\|'" % [code_id, name, name]
    end
  end

  def down
    execute "update name_string_indices set nomenclatural_code_id = null"
  end
end
