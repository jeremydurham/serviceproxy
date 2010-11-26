require 'net/http'
require 'net/https'
require 'uri'

begin
  require 'nokogiri'
  require 'builder'
rescue LoadError
  puts "Could not load nokogiri or builder. Please make sure they are installed and in your $LOAD_PATH."
end

module ServiceProxy
  class Client
    attr_accessor :service_methods, :soap_actions, :http, :uri, :debug, :wsdl, :target_namespace

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
    
  protected

    def setup
      setup_http
      get_wsdl
      parse_wsdl
      generate_methods
    end
  
  private
  
    def setup_http
      raise ArgumentError, "Endpoint URI must be valid" unless self.uri.scheme
      self.http ||= Net::HTTP.new(self.uri.host, self.uri.port)
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
      parser = ServiceProxy::WSDL::Parser.new
      sax_parser = Nokogiri::XML::SAX::Parser.new(parser)
      sax_parser.parse(self.wsdl)
      raise RuntimeError, "Could not parse WSDL" if parser.service_methods.empty?
      self.service_methods = parser.service_methods.sort
      self.target_namespace = parser.target_namespace
      self.soap_actions = parser.soap_actions
    end
    
    def generate_methods
      self.service_methods.each do |service_method|          
        self.class.send(:define_method, service_method) do |*args|
          options = args.pop || {}
          call_service(options.update(:method => service_method))
        end
      
        self.class.send(:define_method, ServiceProxy::Utils.underscore(service_method)) do |*args|
          options = args.pop || {}
          call_service(options.update(:method => service_method))
        end
      end
    end
  
    def build_request(method, options)
      builder  = ServiceProxy::Utils.underscore("build_#{method}")
      self.respond_to?(builder) ? self.send(builder, options).target! : soap_envelope(options).target!
    end
  
    def parse_response(method, response)
      parser = ServiceProxy::Utils.underscore("parse_#{method}")
      if self.respond_to?(parser)
        self.send(parser, response)
      else
        response.body
      end
    end
  
    def soap_envelope(options, &block)
      xsd = 'http://www.w3.org/2001/XMLSchema'
      env = 'http://schemas.xmlsoap.org/soap/envelope/'
      xsi = 'http://www.w3.org/2001/XMLSchema-instance'
      xml = Builder::XmlMarkup.new
      xml.env(:Envelope, 'xmlns:xsd' => xsd, 'xmlns:env' => env, 'xmlns:xsi' => xsi) do
        xml.env(:Body) do
          xml.__send__(options.delete(:method).to_sym, 'xmlns' => self.target_namespace) do
            if block_given?
              yield xml
            else
              options.each do |key, value|
                xml.__send__(key, value)
              end
            end
          end
        end
      end
      xml
    end      
  end
end