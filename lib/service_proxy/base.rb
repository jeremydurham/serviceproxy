require 'net/http'
require 'net/https'
require 'uri'


begin
  require 'nokogiri'
  require 'builder'
rescue LoadError
  puts "Could not load nokogiri or builder. Please make sure they are installed and in your $LOAD_PATH."
end

require File.dirname(__FILE__) + '/parser'
require File.dirname(__FILE__) + '/wsse'

module ServiceProxy
  class Base
    VERSION = '0.2.1'
  
    attr_accessor :service_methods, :soap_actions, :http, :uri, :wsdl, :target_namespace, :wsse
    attr_reader :debug

    def initialize(uri)
      self.uri = URI.parse(uri)
      self.service_methods = []
      self.setup
    end

    def call_service(options)
      method   = options[:method]
      headers  = { 'content-type' => 'text/xml; charset=utf-8', 'SOAPAction' => self.soap_actions[method] }
      body     = build_request(method, options)
      response = self.http.request_post(self.uri.path, body, headers)
      parse_response(method, response)
    end

    def debug=(value)
      @debug = value
      self.http.set_debug_output(STDOUT) if value
    end
    
    def wsse(&block)
      @wsse = ServiceProxy::WSSE.new(&block)
    end
    
    def wsse?
      @wsse.nil? ? false : true
    end
    
  protected

    def setup
      setup_http
      get_wsdl
      parse_wsdl
    end
  
  private
  
    def setup_http
      raise ArgumentError, "Endpoint URI must be valid" unless self.uri.scheme
      self.http = Net::HTTP.new(self.uri.host, self.uri.port)
      setup_https if self.uri.scheme == 'https'
      self.http.set_debug_output(STDOUT) if self.debug
      self.http.read_timeout = 5
    end

    def setup_https
      self.http.use_ssl = true
      self.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
      
    def get_wsdl
      response = self.http.get("#{self.uri.path}?#{self.uri.query}")
      self.wsdl = response.body
    end
      
    def parse_wsdl
      parser = ServiceProxy::Parser.new
      sax_parser = Nokogiri::XML::SAX::Parser.new(parser)
      sax_parser.parse(self.wsdl)
      self.service_methods = parser.service_methods.sort
      self.target_namespace = parser.target_namespace
      self.soap_actions = parser.soap_actions
      raise RuntimeError, "Could not parse WSDL" if self.service_methods.empty?
    end
  
    def build_request(method, options)
      builder  = underscore("build_#{method}")    
      self.respond_to?(builder) ? self.send(builder, options).target! : 
                                  soap_envelope(options).target!
    end
  
    def parse_response(method, response)
      parser = underscore("parse_#{method}")
      self.respond_to?(parser) ? self.send(parser, response) : 
                                 raise(NoMethodError, "You must define the parse method: #{parser}")
    end
    
    def soap_envelope(options, &block)
      xsd = 'http://www.w3.org/2001/XMLSchema'
      env = 'http://schemas.xmlsoap.org/soap/envelope/'
      xsi = 'http://www.w3.org/2001/XMLSchema-instance'
      wsse = 'http://schemas.xmlsoap.org/ws/2002/07/secext'
      wsu = 'http://schemas.xmlsoap.org/ws/2002/07/utility'
      xml = Builder::XmlMarkup.new
      xml.env(:Envelope, 'xmlns:xsd' => xsd, 'xmlns:env' => env, 'xmlns:xsi' => xsi, 'xmlns:wsse' => wsse, 'xmlns:wsu' => wsu) do
        self.wsse.to_xml if self.wsse?
        xml.env(:Body) do
          xml.__send__(options[:method].to_sym, 'xmlns' => self.target_namespace) do
            yield xml if block_given?
          end
        end
      end
      xml
    end
          
    def method_missing(method, *args)
      method_name = method.to_s
      options = args.pop || {}
      super unless self.service_methods.include?(method_name)
      call_service(options.update(:method => method_name))
    end
  
    def underscore(camel_cased_word)
      camel_cased_word.to_s.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end  
  end
end
