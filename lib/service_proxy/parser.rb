module ServiceProxy
  class Parser < Nokogiri::XML::SAX::Document
    attr_accessor :wsdl_namespace, :soap_namespace, :target_namespace, :service_methods, :soap_actions
    
    def initialize(*args)
      self.service_methods = []
      self.soap_actions = Hash.new('')
      super
    end
    
    def start_element_namespace(name, attributes, prefix, uri, namespace)      
      case name
        when 'definitions'
          self.wsdl_namespace = prefix if uri == 'http://schemas.xmlsoap.org/wsdl/'
          self.soap_namespace = prefix if uri == 'http://schemas.xmlsoap.org/wsdl/soap/'
          attribute = attributes.find { |attribute| attribute.localname == 'targetNamespace' }
          self.target_namespace = attribute.value if attribute
        when "operation"
          service_method = attributes.first.value if prefix == self.wsdl_namespace
          soap_action = attributes.find { |attribute| attribute.localname == 'soapAction' }
          self.soap_actions[self.service_methods.last] = soap_action.value if soap_action          
          (self.service_methods << service_method unless self.service_methods.include?(service_method)) if service_method
      end
    end
    
    def end_element_namespace(name, prefix, uri)
    end
  end
end