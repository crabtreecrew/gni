class LexicalMatch < ActiveRecord::Base
  set_primary_keys :canonical_form_id, :matched_canonical_form_id
  belongs_to :canonical_form

  def self.find_matches
    tm = Taxamatch::Base.new
    rows = NameString.connection.select_rows("select lmc.canonical_form_id, lmc.candidate_name, cf1.name, cf2.id from lexical_match_candidates lmc join canonical_forms cf1 on cf1.id = lmc.canonical_form_id join canonical_forms cf2 on cf2.name = lmc.candidate_name")
    count = 0
    rows.each do |row|
      count += 1
      puts "row %s" % count if count % 10000 == 0
      cf1 = row[2].split(' ')
      cf2 = row[1].split(' ')
      next if cf1.size != cf2.size
      genus1 = { :normalized => cf1.shift }
      genus2 = { :normalized => cf2.shift.capitalize }
      res = tm.match_genera(genus1, genus2, :with_phonetic_match => false)
      dist = res["edit_distance"]
      res = res["match"]
      while cf1.size > 0 && res
        sp1 = { :normalized => cf1.shift }
        sp2 = { :normalized => cf2.shift }
        res = tm.match_species(sp1, sp2, :with_phonetic_match => false)
        dist += res["edit_distance"]
        res = res["match"]
      end
      NameString.connection.execute("insert ignore into lexical_matches (canonical_form_id, matched_canonical_form_id, edit_distance, created_at, updated_at) values (%s, %s, %s, now(), now()), (%s, %s, %s, now(), now())" % [row[0], row[3], dist, row[3], row[0], dist]) if res
    end
  end
end
