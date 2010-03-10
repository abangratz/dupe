require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Dupe::Network::Mock do
  before do
    Dupe.reset
  end
  
  describe "new" do
    it "should require a valid REST type" do
      proc { Dupe::Network::Mock.new :unknown, /\//, proc {} }.should raise_error(Dupe::Network::UnknownRestVerbError)
      proc { Dupe::Network::Mock.new :get,     /\//, proc {} }.should_not raise_error
      proc { Dupe::Network::Mock.new :post,    /\//, proc {} }.should_not raise_error
      proc { Dupe::Network::Mock.new :put,     /\//, proc {} }.should_not raise_error
      proc { Dupe::Network::Mock.new :delete,  /\//, proc {} }.should_not raise_error
    end
    
    it "should require the url be a kind of regular expression" do
      proc { Dupe::Network::Mock.new :get, '', proc {} }.should raise_error(
        ArgumentError,
        "The URL pattern parameter must be a type of regular expression."
      )
    end
    
    it "should set the @verb, @url, and @response parameters accordingly" do
      url_pattern = /\//
      response = proc {}
      mock = Dupe::Network::Mock.new :get, url_pattern, response
      mock.verb.should == :get
      mock.url_pattern.should == url_pattern
      mock.response.should == response
    end
  end
  
  describe "match?" do
    it "should determine if a given string matches the mock's url pattern" do
      url = %r{/blogs/(\d+).xml}
      response = proc {}
      mock = Dupe::Network::Mock.new :get, url, response
      mock.match?('/blogs/1.xml').should == true
      mock.match?('/bogs/1.xml').should == false
    end
  end
  
  describe "mocked_response" do
    describe "on a mock object whose response returns a Dupe.find with actual results" do
      it "should convert the response result to xml" do
        url_pattern = %r{/books/(\d+)\.xml}
        response = proc {|id| Dupe.find(:book) {|b| b.id == id.to_i}}
        book = Dupe.create :book
        mock = Dupe::Network::Mock.new :get, url_pattern, response
        mock.mocked_response('/books/1.xml').should == book.to_xml(:root => 'book')
        
        proc { mock.mocked_response('/books/2.xml') }.should raise_error(Dupe::Network::Mock::ResourceNotFoundError)
        
        Dupe.define :author
        mock = Dupe::Network::Mock.new :get, %r{/authors\.xml$}, proc {Dupe.find :authors}
        mock.mocked_response('/authors.xml').should == [].to_xml(:root => 'results')
      end
      
      it "should add a request to the Dupe::Network#log" do
        url_pattern = %r{/books/([a-zA-Z0-9-]+)\.xml}
        response = proc {|label| Dupe.find(:book) {|b| b.label == label}}
        book = Dupe.create :book, :label => 'rooby'
        mock = Dupe::Network::Mock.new :get, url_pattern, response
        Dupe.network.log.requests.length.should == 0
        mock.mocked_response('/books/rooby.xml')
        Dupe.network.log.requests.length.should == 1
      end
    end
    
    describe "on a mock object whose response returns nil" do
      it "should raise an error" do
        url_pattern = %r{/authors/(\d+)\.xml}
        response = proc { |id| Dupe.find(:author) {|a| a.id == id.to_i}}
        Dupe.define :author
        mock = Dupe::Network::Mock.new :get, url_pattern, response
        proc {mock.mocked_response('/authors/1.xml')}.should raise_error(Dupe::Network::Mock::ResourceNotFoundError)
      end
    end
    
    describe "on a mock object whose response returns an empty array" do
      it "should convert the empty array to an xml array record set with root 'results'" do        
        Dupe.define :author
        mock = Dupe::Network::Mock.new :get, %r{/authors\.xml$}, proc {Dupe.find :authors}
        mock.mocked_response('/authors.xml').should == [].to_xml(:root => 'results')
      end
      
      it "should add a request to the Dupe::Network#log" do
        Dupe.define :author
        mock = Dupe::Network::Mock.new :get, %r{/authors\.xml$}, proc {Dupe.find :authors}
        Dupe.network.log.requests.length.should == 0
        mock.mocked_response('/authors.xml')
        Dupe.network.log.requests.length.should == 1
      end
    end
    
    describe "on a mock object whose response returns an array of duped records" do
      it "should convert the array to xml" do        
        Dupe.create :author  
        mock = Dupe::Network::Mock.new :get, %r{/authors\.xml$}, proc {Dupe.find :authors}
        mock.mocked_response('/authors.xml').should == Dupe.find(:authors).to_xml(:root => 'authors')
      end
      
      it "should add a request to the Dupe::Network#log" do
        Dupe.create :author
        mock = Dupe::Network::Mock.new :get, %r{/authors\.xml$}, proc {Dupe.find :authors}
        Dupe.network.log.requests.length.should == 0
        mock.mocked_response('/authors.xml')
        Dupe.network.log.requests.length.should == 1
      end
    end
    
    describe "on a mock object whose response returns a location of a new record" do
      it "should convert the new post to xml" do        
        Dupe.create :author  
        mock = Dupe::Network::Mock.new :post, %r{/authors\.xml$}, proc {Dupe.find(:authors) {|a| a.id == 1}}
        mock.mocked_response('/authors.xml').should == Dupe.find(:authors) {|a| a.id == 1}.to_xml(:root => 'authors')
      end
      
      it "should add a request to the Dupe::Network#log" do
        Dupe.create :author
        mock = Dupe::Network::Mock.new :post, %r{/authors\.xml$}, proc {Dupe.find(:authors) {|a| a.id == 1}}
        Dupe.network.log.requests.length.should == 0
        mock.mocked_response('/authors.xml')
        Dupe.network.log.requests.length.should == 1
      end
    end
  end
  
  
end
