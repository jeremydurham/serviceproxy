require 'rubygems'
require 'spec'
require 'lib/service_proxy/base'
require 'spec/service_helper'

describe ServiceProxy do  
  it "should raise on an invalid URI" do
    lambda { ServiceProxy::Base.new('bacon') }.should raise_error(ArgumentError)
  end
  
  it "should raise on invalid WSDL" do
    lambda { ServiceProxy::Base.new('http://www.yahoo.com') }.should raise_error(RuntimeError)
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
  
  describe "connecting to the Ebay Service" do
    before do
      @proxy = EbayService.new('http://developer.ebay.com/webservices/latest/eBaySvc.wsdl')
    end
    
    it "should have methods" do
      @proxy.service_methods.should_not be_nil
    end
  end
  
  describe "connect to the Zipcode Service" do
    before do
      @proxy = ZipcodeService.new('http://ws.fraudlabs.com/zipcodeworldUS_webservice.asmx?wsdl')
    end
    
    it "should not fail" do
      @proxy.ZIPCodeWorld_US.should_not be_nil
    end
  end
  
  describe "making a service call without a parse method" do
    before do
      @proxy = InvalidSHAGeneratorService.new('https://sec.neurofuzz-software.com/paos/genSSHA-SOAP.php?wsdl')
    end
  
    it "should be SSL" do
      @proxy.http.use_ssl.should be_true
    end
  
    it "should raise a no method error" do
      lambda { result = @proxy.genSSHA(:text => 'hello world', :hash_type => 'sha512') }.should raise_error(NoMethodError)
    end
  end
  
end