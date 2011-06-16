module MSDynamics
  class CrmService
    def initialize(crm_service_url,crm_ticket,user_organization)
      @crm_service_url, @crm_ticket, @user_organization = 
        crm_service_url, crm_ticket, user_organization
    end
    
    def request(request_name)
      message = compose_message(
        "<Execute xmlns=\"http://schemas.microsoft.com/crm/2007/WebServices\">
           <Request xsi:type=\"#{request_name}\"/>
         </Execute>")
      execute_request(message,'Execute')
    end
    
    def retrieve(entity_name,entity_id,attributes)
      columns = attributes.collect { |attrib| "<q1:Attribute>#{attrib}</q1:Attribute>" }
      message = compose_message(
        "<Retrieve xmlns='http://schemas.microsoft.com/crm/2007/WebServices'>
          <entityName>#{entity_name}</entityName>
          <id>#{entity_id}</id>
          <columnSet xmlns:q1='http://schemas.microsoft.com/crm/2006/Query' xsi:type='q1:ColumnSet'>
            <q1:Attributes> 
              #{columns.to_s} 
            </q1:Attributes> 
          </columnSet> 
        </Retrieve>")
      execute_request(message,'Retrieve')
    end
    
    def get_current_user
      doc = request('WhoAmIRequest')
      select_node_text(doc,'UserId')
    end
    
    def get_current_user_full_name(user_id)
      doc = retrieve('systemuser',user_id,['fullname'])
      select_node_text(doc,'fullname')   
    end  
    
    private
    def compose_message(body)
      "<?xml version=\"1.0\" encoding=\"utf-8\"?>
      <soap:Envelope 
      xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\" 
      xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" 
      xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\">
        <soap:Header>
          <CrmAuthenticationToken xmlns=\"http://schemas.microsoft.com/crm/2007/WebServices\">
            <AuthenticationType xmlns=\"http://schemas.microsoft.com/crm/2007/CoreTypes\">1</AuthenticationType>
            <CrmTicket xmlns=\"http://schemas.microsoft.com/crm/2007/CoreTypes\">#{@crm_ticket}</CrmTicket>
            <OrganizationName xmlns=\"http://schemas.microsoft.com/crm/2007/CoreTypes\">#{@user_organization}</OrganizationName>
            <CallerId xmlns=\"http://schemas.microsoft.com/crm/2007/CoreTypes\">00000000-0000-0000-0000-000000000000</CallerId>
          </CrmAuthenticationToken>
        </soap:Header>
        <soap:Body>
          #{body}
        </soap:Body>
      </soap:Envelope>"
    end
    
    def execute_request(message,action)
      begin
        response = RestClient.post(@crm_service_url, message,
          { :content_type => "text/xml; charset=UTF-8",
            "SOAPAction" => "http://schemas.microsoft.com/crm/2007/WebServices/#{action}" })
        Nokogiri::XML(response)
      rescue RestClient::Exception => ex
        warn "CrmService error: " + ex.inspect
        raise ex
      end
    end  
      
    def select_node_text(doc,node_name)
      doc.xpath("//ns:#{node_name}/text()",
        {'ns'=>'http://schemas.microsoft.com/crm/2007/WebServices'}).to_s.strip
    end
      
  end
end