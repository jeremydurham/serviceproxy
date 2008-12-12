require 'rubygems'
require 'nokogiri'
require 'net/http'
require 'net/https'
require 'builder'
require 'uri'

class ServiceProxy
  VERSION = '0.0.1'
  
  attr_accessor :endpoint, :service_methods, :soap_actions, :service_uri, :http, :uri, :debug, :wsdl, :target_namespace

  def initialize(endpoint)
    self.endpoint = endpoint
    self.setup
  end

protected

  def setup
    self.soap_actions = {}
    self.service_methods = []
    setup_http
    get_wsdl
    parse_wsdl
    setup_namespace
  end
  
private
  
  def setup_http
    self.uri = URI.parse(self.endpoint)
    raise ArgumentError, "Endpoint URI must be valid" unless self.uri.scheme
    self.http = Net::HTTP.new(self.uri.host, self.uri.port)
    self.http.use_ssl = true if self.uri.scheme == 'https'                                                                            
    self.http.set_debug_output(STDOUT) if self.debug
  end
  
  def get_wsdl
    response = self.http.get("#{self.uri.path}?#{self.uri.query}")
    self.wsdl = Nokogiri.XML(response.body)    
  end
  
  def parse_wsdl
    method_list = []    
    self.wsdl.xpath('//*[name()="soap:operation"]').each do |operation|
      operation_name = operation.parent.get_attribute('name')
      method_list << operation_name
      self.soap_actions[operation_name] = operation.get_attribute('soapAction')
    end
    raise RuntimeError, "Could not parse WSDL" if method_list.empty?
    self.service_methods = method_list.sort
  end
  
  def setup_namespace
    self.target_namespace = self.wsdl.namespaces['xmlns:tns']
  end
  
  def call_service(options)
    method   = options[:method]
    headers  = { 'content-type' => 'text/xml; charset=utf-8', 'SOAPAction' => self.soap_actions[method] }
    body     = build_request(method, options)
    response = self.http.request_post(self.uri.path, body, headers)    
    parse_response(method, response)
  end
  
  def build_request(method, options)
    builder  = underscore("build_#{method}")    
    self.respond_to?(builder) ? self.send(builder, options).target! : soap_envelope(options).target!
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
    xml = Builder::XmlMarkup.new
    xml.env(:Envelope, 'xmlns:xsd' => xsd, 'xmlns:env' => env, 'xmlns:xsi' => xsi) do
      xml.env(:Body) do
        xml.__send__(options[:method].to_sym, "xmlns" => self.target_namespace) do        
          yield xml if block_given?
        end
      end
    end
    xml
  end
  
  def method_missing(method, *args)
    options = args.pop || {}
    super unless self.service_methods.include?(method.to_s)
    call_service(options.update(:method => method.to_s))
  end
  
  def underscore(camel_cased_word)
    camel_cased_word.to_s.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
  end  
end