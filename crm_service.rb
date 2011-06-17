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
      message = SoapService.compose_message(@message_header,
        "<Retrieve xmlns='http://schemas.microsoft.com/crm/2007/WebServices'>
          <entityName>#{entity_name}</entityName>
          <id>#{entity_id}</id>
          <columnSet xmlns:q1='http://schemas.microsoft.com/crm/2006/Query' xsi:type='q1:ColumnSet'>
            <q1:Attributes> 
              #{get_columns(attributes)} 
            </q1:Attributes> 
          </columnSet> 
        </Retrieve>")
      doc = SoapService.send_request(@crm_service_url,message,get_action('Retrieve'))
      res = {}
      attributes.each do |attribute|
        res.merge!(attribute => MSDynamics::SoapService.select_node_text(doc,"cws7:#{attribute}"))
      end
      res
    end
        
    def retrieve_multiple(entity_name, attributes, distinct=true, criteria_xml="")
      message = SoapService.compose_message(@message_header,
        "<RetrieveMultiple xmlns='http://schemas.microsoft.com/crm/2007/WebServices'>
          <query xmlns:q1='http://schemas.microsoft.com/crm/2006/Query' xsi:type='q1:QueryExpression'>
            <q1:EntityName>#{entity_name}</q1:EntityName>
            <q1:ColumnSet xsi:type='q1:ColumnSet'>
              <q1:Attributes>
                #{get_columns(attributes)} 
              </q1:Attributes>
            </q1:ColumnSet>
            <q1:Distinct>#{distinct.to_s}</q1:Distinct>
            #{criteria_xml}
          </query>
        </RetrieveMultiple>")      
      doc = SoapService.send_request(@crm_service_url,message,get_action('RetrieveMultiple'))
      business_entities = SoapService.select_node(doc,'cws6:BusinessEntity')
      business_entities.collect do |business_entity|
        attributes = {}
        business_entity.children.each do |attrib|
          attributes.merge!(attrib.name => attrib.text)
        end
        attributes
      end
    end  
    
    def get_current_user
      doc = request('WhoAmIRequest')
      SoapService.select_node_text(doc,'cws7:UserId')
    end
        
    private
    def get_action(name)
      "http://schemas.microsoft.com/crm/2007/WebServices/#{name}"
    end
    
    def get_columns(attributes)
      columns = attributes.collect { |attrib| "<q1:Attribute>#{attrib}</q1:Attribute>" }
      columns.to_s
    end
  end
end