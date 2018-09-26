class Util
  def self.underscore(term)
    # taken from ActiveSupport
    term.gsub(/::/, '/')
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .tr('-', '_')
        .downcase
  end

  def self.classify(term)
    term.split('_').collect(&:capitalize).join
  end
end
