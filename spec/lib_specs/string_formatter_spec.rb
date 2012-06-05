require 'spec_helper'

describe String do 
  
  describe "indent" do
    it "should default the indentional level to 2 spaces" do
     StringFormatter.indent('apples').should == "  apples"
    end
    
    it "should accept an indentional level" do
      StringFormatter.indent('apples', 4).should == "    apples"
    end
    
    it "should indent each line of the string" do
      StringFormatter.indent("apples\noranges", 2).should == "  apples\n  oranges"
    end
  end
end
