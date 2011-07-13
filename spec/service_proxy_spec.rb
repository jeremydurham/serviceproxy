require 'rubygems'
require 'rspec'
require 'service_proxy'
require 'service_helper'

describe ServiceProxy do
  describe ServiceProxy::Client do

    describe "initializing" do
      it "should raise on an invalid URI" do
        lambda { ServiceProxy::Client.new('bacon') }.should raise_error(ArgumentError)
      end

      it "should raise on invalid WSDL" do
        lambda { ServiceProxy::Client.new('http://www.yahoo.com') }.should raise_error(RuntimeError)
      end
    end

    describe "calling an action on a service" do
      before do
        @proxy = ServiceProxy::Client.new('http://webservices.daehosting.com/services/isbnservice.wso?WSDL')
      end

      it "should not raise an error without a build or parse method" do
        lambda { @proxy.IsValidISBN13(:sISBN => '978-0977616633') }.should_not raise_error
      end

      it "should not use method_missing to call the service" do
        @proxy.respond_to?(:IsValidISBN13).should be_true
      end

      it "should support Ruby style methods" do
        @proxy.respond_to?(:is_valid_isbn13).should be_true
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
        @proxy.http.use_ssl?.should be_true
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

      it "should be successful" do
        @proxy.GetUser.should_not be_nil
      end
    end

    describe "connecting to the IBAN validate service" do
      before do
        @proxy = ServiceProxy::Client.new('http://www.unifiedsoftware.co.uk/freeibanvalidate.wsdl')
      end

      it "should be successful" do
        pending "Fix this or provide instructions on spec setup."
        @proxy.call_service(:method => 'urn:ibanvalidate', :params => 'DE47200505501280133503').should == 'VALID'
      end
    end

    describe "connecting to the Zipcode Service" do
      before do
        @proxy = ZipcodeService.new('http://ws.fraudlabs.com/zipcodeworldUS_webservice.asmx?wsdl')
      end

      it "should be successful" do
        @proxy.ZIPCodeWorld_US.should_not be_nil
      end
    end

    describe "connecting to the Daily .NET fact Service" do
      before do
        @proxy = DailyDotNetFactService.new('http://www.xmlme.com/WSDailyNet.asmx?WSDL')
      end

      it "should be successful" do
        @proxy.GetDotnetDailyFact.should_not be_nil
      end
    end

    describe "debugging a service call" do
      before do
        @proxy = ZipcodeService.new('http://ws.fraudlabs.com/zipcodeworldUS_webservice.asmx?wsdl')
      end

      it "should set_debug_output on the HTTP connection" do
        @proxy.http.should_receive(:set_debug_output)
        @proxy.debug!
      end
    end
  end
end