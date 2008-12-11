require 'rubygems'
require 'spec'
require File.dirname(__FILE__) + '/../lib/service_proxy.rb'
require File.dirname(__FILE__) + '/service_helper.rb'

describe ServiceProxy do  
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
        result.should be_nil
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
  
  describe "connecting to a Digital Encryption Service" do
    before do
      @proxy = DigitalEncryptionService.new('https://labs.safelayer.com/demo/wsdl/DigitalEncryption.wsdl')
    end
  end
end