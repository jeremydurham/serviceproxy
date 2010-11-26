class SOAPFault
  attr_accessor :fault_code, :fault_string, :fault_actor, :detail
  
  def to_xml
=begin
<env:Fault>
 <faultcode><value>env:VersionMismatch</value></faultcode>
  <faultstring>Version Mismatch</faultstring>
 </env:Fault>
=end        
  end
end