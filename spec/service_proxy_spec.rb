require 'rubygems'
require 'spec'
require File.dirname(__FILE__) + '/../lib/service_proxy.rb'
require File.dirname(__FILE__) + '/service_helper.rb'

describe ServiceProxy do  
  it "should raise on an invalid URI" do
    lambda { ServiceProxy.new('bacon') }.should raise_error(ArgumentError)
  end
  
  it "should raise on invalid WSDL" do
    lambda { ServiceProxy.new('http://www.yahoo.com') }.should raise_error(RuntimeError)
  end
    
  describe "connecting to an Instant Message Service" do
    before do
      @proxy = InstantMessageService.new('http://www.imcomponents.com/imsoap/?wsdl')
    end
    
    describe "calling GetVersion" do
      it "should return the version" do        
        version = @proxy.GetVersion
        version.should == 'v1.0.20080508'
      end
    end
    
    describe "calling Login" do
      it "should return nil" do
        result = @proxy.Login(:userId => 'test', :password => 'test')
        result.should == 'Invalid username/password'
      end
    end
  end
  
  describe "connecting to an ISBN validator" do
    before do
      @proxy = ISBNService.new('http://webservices.daehosting.com/services/isbnservice.wso?WSDL')
    end
    
    describe "calling IsValidISBN13" do
      it "should return true for a valid ISBN" do
        @proxy.IsValidISBN13(:isbn => '978-0977616633').should == true
      end
      
      it "should return false for an invalid ISBN" do
        @proxy.IsValidISBN13(:isbn => '999-9999391939').should == false
      end
    end
  end
  
  describe "connecting to the SHA hash generator Service" do
    before do
      @proxy = SHAGeneratorService.new('https://sec.neurofuzz-software.com/paos/genSSHA-SOAP.php?wsdl')
    end
    
    it "should be SSL" do
      @proxy.http.use_ssl.should be_true
    end
    
    it "should generate a SSH hash" do
      result = @proxy.genSSHA(:text => 'hello world', :hash_type => 'sha512')
      result.should =~ /^[{SSHA512}]/
    end
  end
  
  describe "making a service call without a parse method" do
    before do
      @proxy = InvalidSHAGeneratorService.new('https://sec.neurofuzz-software.com/paos/genSSHA-SOAP.php?wsdl')
    end
  
    it "should raise a no method error" do
      lambda { result = @proxy.genSSHA(:text => 'hello world', :hash_type => 'sha512') }.should raise_error(NoMethodError)
    end
  end
  
  describe "using the #service_port hook" do
    before do
      @proxy = ISBNService.new('http://webservices.daehosting.com/services/isbnservice.wso?WSDL')
    end
    
    it "should have the dummy query argument" do
      @proxy.send(:service_uri).path.should match(/\?dummy=1/)
    end
  end
end