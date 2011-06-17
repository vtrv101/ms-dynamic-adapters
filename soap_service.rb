module MSDynamics  
  # use node_namespaces attribute to specify namespaces used 
  # by SoapService's select_node and select_node_text methods
  class << self; attr_accessor :node_namespaces end
  @node_namespaces = {
    'cds' => 'http://schemas.microsoft.com/crm/2007/CrmDiscoveryService',
    'wst' => 'http://schemas.xmlsoap.org/ws/2005/02/trust',
    'wsu' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd',
    'wsse'=> 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd',
    's'   => 'http://www.w3.org/2003/05/soap-envelope',
    'psf' => 'http://schemas.microsoft.com/Passport/SoapServices/SOAPFault'
  }    

  class SoapService
    class << self      
      def select_node(doc,node_name)
        doc.xpath("//#{node_name}",MSDynamics.node_namespaces)
      end

      def select_node_text(doc,node_name)
        doc.xpath("//#{node_name}/text()",MSDynamics.node_namespaces).to_s.strip
      end

      def compose_message(header,body)
        hdr = header ? "<s:Header>#{header}</s:Header>" : ""
        bdy = body ? "<s:Body>#{body}</s:Body>" : ""
        "<?xml version=\"1.0\"?>
         <s:Envelope 
           xmlns:s=\"http://www.w3.org/2003/05/soap-envelope\" 
           xmlns:wsse=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd\" 
           xmlns:wsp=\"http://schemas.xmlsoap.org/ws/2004/09/policy\" 
           xmlns:wsu=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd\" 
           xmlns:wsa=\"http://www.w3.org/2005/08/addressing\" 
           xmlns:wst=\"http://schemas.xmlsoap.org/ws/2005/02/trust\">
           #{hdr}
           #{bdy}
         </s:Envelope>"        
      end
      
      def send_request(endpoint,message,action=nil,content_type='text/xml; charset=UTF-8')
        begin
          headers = { :content_type => content_type }
          headers.merge!({ "SOAPAction" => action }) if action
          response = RestClient.post(endpoint, message, headers)
          Nokogiri::XML(response)
        rescue RestClient::Exception => ex
          warn "#{self.name} error: " + ex.inspect.strip
          ex.backtrace.each { |line| warn 'from ' + line } 
          raise ex
        end
      end  
      
    end
  end
end
