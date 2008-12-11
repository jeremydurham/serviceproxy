require 'hpricot'

# Service Endpoints
class InstantMessageService < ServiceProxy
  
  def parse_get_version(response)
    xml = Hpricot.XML(response.body)
    xml.at("GetVersionResult").inner_html
  end
  
  def build_login(options)
    soap_envelope(options) do |xml|
      xml.userId(options[:userId])
      xml.password(options[:password])
    end
  end
  
  def parse_login(response)
    'Invalid username/password' if response.code == "500"
  end
end

class ISBNService < ServiceProxy  
  
  def build_is_valid_isbn13(options)
    soap_envelope(options) do |xml|
      xml.sISBN(options[:isbn])
    end
  end
  
  def parse_is_valid_isbn13(response)
    xml = Hpricot.XML(response.body)
    xml.at("m:IsValidISBN13Result").inner_html == 'true' ? true : false
  end
end

class SHAGeneratorService < ServiceProxy
  
  def parse_gen_ssha(response)
    response
  end
end