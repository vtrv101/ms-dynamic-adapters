module MSDynamics
  class CrmService < SoapService
    def initialize(crm_service_url,crm_ticket,user_organization)
      @crm_service_url = crm_service_url
      @message_header  = "
      <CrmAuthenticationToken xmlns=\"http://schemas.microsoft.com/crm/2007/WebServices\">
        <AuthenticationType xmlns=\"http://schemas.microsoft.com/crm/2007/CoreTypes\">1</AuthenticationType>
        <CrmTicket xmlns=\"http://schemas.microsoft.com/crm/2007/CoreTypes\">#{crm_ticket}</CrmTicket>
        <OrganizationName xmlns=\"http://schemas.microsoft.com/crm/2007/CoreTypes\">#{user_organization}</OrganizationName>
        <CallerId xmlns=\"http://schemas.microsoft.com/crm/2007/CoreTypes\">00000000-0000-0000-0000-000000000000</CallerId>
      </CrmAuthenticationToken>"  
    end
    
    def request(request_name)
      message = SoapService.compose_message(@message_header,
        "<Execute xmlns=\"http://schemas.microsoft.com/crm/2007/WebServices\">
           <Request xsi:type=\"#{request_name}\"/>
         </Execute>")
      SoapService.send_request(@crm_service_url,message,get_action('Execute'))
    end
    
    def retrieve(entity_name,entity_id,attributes)
      columns = attributes.collect { |attrib| "<q1:Attribute>#{attrib}</q1:Attribute>" }
      message = SoapService.compose_message(@message_header,
        "<Retrieve xmlns='http://schemas.microsoft.com/crm/2007/WebServices'>
          <entityName>#{entity_name}</entityName>
          <id>#{entity_id}</id>
          <columnSet xmlns:q1='http://schemas.microsoft.com/crm/2006/Query' xsi:type='q1:ColumnSet'>
            <q1:Attributes> 
              #{columns.to_s} 
            </q1:Attributes> 
          </columnSet> 
        </Retrieve>")
      SoapService.send_request(@crm_service_url,message,get_action('Retrieve'))
    end
    
    def get_current_user
      doc = request('WhoAmIRequest')
      SoapService.select_node_text(doc,'cws:UserId')
    end
    
    def get_current_user_full_name(user_id)
      doc = retrieve('systemuser',user_id,['fullname'])
      SoapService.select_node_text(doc,'cws:fullname')   
    end  
    
    private
    def get_action(name)
      "http://schemas.microsoft.com/crm/2007/WebServices/#{name}"
    end
  end
end