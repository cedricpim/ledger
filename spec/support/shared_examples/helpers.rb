class RSpecHelper
  class << self
    def headers(klass)
      klass.members.map(&:capitalize).join(',')
    end

    def build_result(klass, *entries)
      ([headers(klass)] + entries.map(&:to_file)).join("\n")
    end
  end
end
