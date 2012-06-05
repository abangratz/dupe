class StringFormatter #:nodoc:
  def self.indent(string="", spaces=2)
    string.split("\n").map {|l| (" " * spaces) + l }.join("\n")
  end
end
