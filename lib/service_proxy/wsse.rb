require 'base64'

module ServiceProxy
  class WSSE
    attr_accessor :username, :password
    attr_writer :created_at
    
    def initialize
      yield self if block_given?
    end
        
    def password_digest
      return password unless self.digest?

      Base64.encode64(Digest::SHA1.hexdigest(self.nonce + self.created_at + self.password)).chomp
    end
    
    def nonce
      Base64.encode64(rand(999_999_999).to_s).chomp
    end
        
    def created_at
      (@created_at || Time.now).strftime("%FT%TZ")
    end
    
    def to_xml
      xml.env(:Header) do
        xml.wsse(:Security, 'xmlns:wsse' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd') do
          xml.wsse(:UsernameToken, 'xmlns:wsu' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd') do
            xml.wsse(:Username, username)
            xml.wsse(:Password, password)
            xml.wsse(:Nonce, nonce)
            xml.wsse(:Created, created_at)
          end
        end
      end
    end
  end
end