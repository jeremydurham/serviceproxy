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
    attr_accessor :soap_actions, :http, :uri, :debug, :wsdl, :namespaces

    def initialize(uri)
      self.uri = URI.parse(uri)
      self.setup
    end

    def call_service(options)
      method   = options[:method]
      headers  = { 'content-type' => 'text/xml; charset=utf-8' }
      body     = build_request(method, options)
      response = self.http.request_post(self.uri.path, body, headers)
      parse_response(method, response)
    end

    def debug=(value)
      @debug = value
      self.http.set_debug_output(STDOUT) if value
    end
    
    def debug!
      debug = true
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
      raise RuntimeError, "Could not parse WSDL" if parser.soap_actions.empty?
      self.namespaces = parser.namespaces
      self.soap_actions = parser.soap_actions
    end
    
    def generate_methods
      self.soap_actions.keys.each do |soap_action|
        self.class.send(:define_method, soap_action) do |*args|
          options = args.pop || {}
          call_service(options.update(:method => soap_action))
        end
      
        self.class.class_eval do
          # alias test_method to testMethod (defined above), to be more Ruby-like
          alias_method :"#{ServiceProxy::Utils.underscore(soap_action)}", "#{soap_action}"
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
        Nokogiri.XML(response.body)
      end
    end
  
    def soap_envelope(options, &block)
      xml = Builder::XmlMarkup.new
      xml.env(:Envelope, self.namespaces) do
        xml.env(:Body) do
          xml.__send__(options.delete(:method).to_sym, 'xmlns' => self.namespaces["xmlns:tns"]) do
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