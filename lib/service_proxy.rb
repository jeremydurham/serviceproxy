require 'rubygems'
require 'nokogiri'
require 'net/http'
require 'net/https'
require 'builder'
require 'uri'

class ServiceProxy
  VERSION = '0.0.1'
  
  attr_accessor :endpoint, :service_methods, :soap_actions, :service_uri, :http, :service_http, :uri, :debug, :wsdl, :target_namespace, :service_ports

  def initialize(endpoint)
    self.endpoint = endpoint
    self.setup
  end
  
  def call_service(options)
    method   = options[:method]
    headers  = { 'content-type' => 'text/xml; charset=utf-8', 'SOAPAction' => self.soap_actions[method] }
    body     = build_request(method, options)
    response = self.service_http.request_post(self.service_uri.path, body, headers)    
    parse_response(method, response)
  end  

protected

  def setup
    self.soap_actions = {}
    self.service_methods = []
    setup_uri
    self.http = setup_http(self.uri)
    get_wsdl
    parse_wsdl
    setup_namespace
  end
  
  def service_uri
    @service_uri ||= if self.respond_to?(:service_port)
      self.service_port
    else
      self.uri
    end
  end
  
  def service_http
    @service_http ||= unless self.service_uri == self.uri
      local_http = self.setup_http(self.service_uri)
      setup_https(local_http) if self.service_uri.scheme == 'https'
      local_http
    else
      self.http
    end
  end
  
  def setup_http(local_uri)
    raise ArgumentError, "Endpoint URI must be valid" unless local_uri.scheme    
    local_http = Net::HTTP.new(local_uri.host, local_uri.port)
    setup_https(local_http) if local_uri.scheme == 'https'
    local_http.set_debug_output(STDOUT) if self.debug
    local_http.read_timeout = 5
    local_http
  end

  def setup_https(local_http)
    local_http.use_ssl = true
    local_http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
  
private
  
  def setup_uri
    self.uri = URI.parse(self.endpoint)
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
    
    port_list = {}
    self.wsdl.xpath('//wsdl:port', {"xmlns:wsdl" => 'http://schemas.xmlsoap.org/wsdl/'}).each do |port|
      name = underscore(port['name'])
      location = port.xpath('./*[@location]').first['location']
      port_list[name] = location
    end
    self.service_ports = port_list
  end
  
  def setup_namespace
    self.target_namespace = self.wsdl.namespaces['xmlns:tns']
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
    method_name = method.to_s
    case method_name
    when /_uri$/
      sp_name = method_name.gsub(/_uri$/, '')
      super unless self.service_ports.has_key?(sp_name)
      URI.parse(self.service_ports[sp_name])
    else
      options = args.pop || {}
      super unless self.service_methods.include?(method_name)
      call_service(options.update(:method => method_name))
    end
  end
  
  def underscore(camel_cased_word)
    camel_cased_word.to_s.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
  end  
end