require 'iconv'
class ExternalListReconciler < ActiveRecord::Base
  belongs_to :progress_status
  
  def self.perform(reconciler_id)
    r = Reconciler.find(reconciler_id)
    r.reconcile
  end

  def self.read_file(file_path)
    conv = Iconv.new('UTF-8', 'ISO-8859-1')
    open(file_path).inject([]) do |res, line|
      #for now we assume that non-utf8 charachters are in latin1, might need to add others
      line = conv.conv(line) unless line.valid_encoding?
      line = line.strip.gsub("\t", "|")
      fields = line.split("|")
      name = id = nil
      return res if fields.blank?
      if fields.size == 1
        name = fields[0].strip
      elsif fields.size > 1
        id = fields[0].strip
        name = fields[1].strip
      end
      res << { :id => id, :name_string => name }    
      res
    end
  end

  def reconcile
    require 'ruby-debug'; debugger
    puts ''
  end


end
