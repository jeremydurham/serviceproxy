module ServiceProxy
  module WSDL
    class Parser < Nokogiri::XML::SAX::Document
      attr_accessor :bindings, :services, :namespaces, :operations, :soap_actions
      
      attr_accessor :current_operation

      def initialize(*args)
        self.operations = []
        self.soap_actions = {}
        # Default namespaces
        self.namespaces = { "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema",
                            "xmlns:env" => "http://schemas.xmlsoap.org/soap/envelope/",
                            "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance" }
        super
      end

      def start_element_namespace(name, attributes, prefix, uri, namespace)
        case name
          when 'definitions'
            namespace.each do |namespace, value|
              if namespace
                self.namespaces["xmlns:#{namespace}"] = value
              end
            end
          when 'operation'
            if uri == 'http://schemas.xmlsoap.org/wsdl/soap/'
              self.soap_actions[self.current_operation] = attributes.first.value
            else
              self.current_operation = attributes.first.value
              self.operations << self.current_operation
            end
        end
      end
    end
  end
end