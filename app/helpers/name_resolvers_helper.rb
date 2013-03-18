module NameResolversHelper
  def classification_path(result)
    classification = result[:classification_path].split('|')
    ranks = result[:classification_path_ranks].split('|')
    classification = classification.zip(ranks).inject([]) do |res, item|
      if item[1].empty?
        res << item[0]
      else
        res << "%s (%s)" % item
      end
    end
    classification.join(' >> ')
  end
end
