module GNI
  class Parser
    def initialize 
      @parallel_parser = ParallelParser.new
      @parser = ScientificNameParser.new
    end

    def parse_list(name_list)
      @parallel_parser.parse(name_list)
    end

    def parse(name)
      @parser.parse(name)
    end
  end
end
