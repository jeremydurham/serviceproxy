# Service Endpoints
class ISBNService < ServiceProxy::Base  
  
  def build_is_valid_isbn13(options)
    soap_envelope(options) do |xml|
      xml.sISBN(options[:isbn])
    end
  end
  
  def parse_is_valid_isbn13(response)
    xml = Nokogiri.XML(response.body)
    namespace = { 'm' => 'http://webservices.daehosting.com/ISBN' }
    xml.at('//m:IsValidISBN13Result', namespace).inner_text == 'true' ? true : false
  end  
end

class SHAGeneratorService < ServiceProxy::Base
  
  def build_gen_ssha(options)
    soap_envelope(options) do |xml|
      xml.text(options[:text])
      xml.hashtype(options[:hash_type])
    end
  end
  
  def parse_gen_ssha(response)
    xml = Nokogiri.XML(response.body)
    xml.at("return").inner_text
  end
end

class InvalidSHAGeneratorService < ServiceProxy::Base
  
  def build_gen_ssha(options)
    soap_envelope(options) do |xml|
      xml.text(options[:text])
      xml.hashtype(options[:hash_type])
    end
  end
  
end

class EbayService < ServiceProxy::Base
  def build_get_user(options)
    soap_envelope(options) do |xml|
      xml.GetUserRequest do
      end
    end
  end

  def parse_get_user(response)
    Nokogiri.XML(response.body)
  end
end

class ZipcodeService < ServiceProxy::Base

  def build_zip_code_world_us(options)
    soap_envelope(options) do |xml|
    end
  end

  def parse_zip_code_world_us(response)
    xml = Nokogiri.XML(response.body)
  end

end

class DailyDotNetFactService < ServiceProxy::Base
  def build_get_dotnet_daily_fact(options)
    soap_envelope(options) do |xml|
    end
  end

  def parse_get_dotnet_daily_fact(response)
    xml = Nokogiri.XML(response.body)
    xml.at('//xmlns:GetDotnetDailyFactResult', 'xmlns' => 'http://xmlme.com/WebServices').inner_text
  end
end

class WSSEService < ServiceProxy::Base
end