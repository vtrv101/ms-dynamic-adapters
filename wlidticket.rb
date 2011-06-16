module MSDynamics
  class WLIDTicket
    def self.get_ticket(user_name,password)
      # device client ID
      client_id = UUIDTools::UUID.random_create
      # random device name
      device_name = rand(10000).to_s+'12345678901234567890'
      # random device password
      device_password = 'random-device-password'
      # authentication policy
      policy = "MBI_SSL"
      # open information about CRM Online
      partner = "crm.dynamics.com";

      # Get authorization endpoint  
      authorization_endpoint = self._get_authorization_endpoint

      # Do the following once per machine.  
      # Register each machine that you need to authenticate with.
      self._register_machine(device_name,device_password,client_id)
    
      # Get device token based for the registered machine
      device_token = self._get_device_token(authorization_endpoint,device_name,device_password)

      #Get WLID Ticket for the user
      self._get_ticket(authorization_endpoint,user_name,password,partner,policy,client_id,device_token)
    end
  
    private
    class << self
      def _get_federation_metadata
        open("https://nexus.passport.com/federationmetadata/2006-12/FederationMetaData.xml")
      end  

      def _get_authorization_endpoint
        federation_metadata = Nokogiri::XML(_get_federation_metadata)
        federation_metadata.xpath("//fed:FederationMetadata/fed:Federation/fed:TargetServiceEndpoint/wsa:Address").text.strip
      end

      # Registers a machine/device with the device registration Windows Live ID service. 
      # Device registration is required only once per computer or device.
      # The result of this request will contain the PUID (Device ID) of the device registered 
      # and should be saved for later use.
      # device_name - The random device name to use for this registration.
      # device_password - The random device password to use for this registration.
      # client_id - The app GUID, a unique id for the client/application.
      def _register_machine(device_name,device_password,client_id)
        device_registration_request =
          "<DeviceAddRequest>
            <ClientInfo name=\"#{client_id}\" version=\"1.0\"/>
            <Authentication>
              <Membername>11#{device_name}</Membername>
              <Password>#{device_password}</Password>
            </Authentication>
          </DeviceAddRequest>"
        windowsLiveDeviceUrl = "https://login.live.com/ppsecure/DeviceAddCredential.srf"
        res = RestClient.post(windowsLiveDeviceUrl, device_registration_request, :content_type => "application/soap+xml; charset=UTF-8").to_s
        raise "Can't register machine with Wndows Live ID" if Nokogiri::XML(res).xpath("/DeviceAddResponse/@Success").to_s.strip != 'true'
      end

      # Validate Windows Live ID response for any exception.
      # doc - The Windows Live ID service response.
      # source - An exception source.
      # Raise runtime error is request is invalid 
      def _is_response_valid(doc,source)
        if doc.xpath("S:Envelope/S:Body/S:Fault").size > 0
          error = doc.xpath("S:Envelope/S:Body/S:Fault/S:Reason/S:Text").text rescue "Unknown error"
          raise "Error #{source}: #{error}"
        end
      end

      # Get a device authorization token from the Windows Live ID service.
      # authorization_endpoint - Authorization endpoint
      # device_name - The random device name used for this registration.
      # device_password - The random device password used for this registration.
      # Returns - The device token to use when retrieving a user token
      def _get_device_token(authorization_endpoint,device_name,device_password)
        device_token_request = "<?xml version=\"1.0\"?>
          <s:Envelope 
            xmlns:s=\"http://www.w3.org/2003/05/soap-envelope\" 
            xmlns:wsse=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd\" 
            xmlns:wsp=\"http://schemas.xmlsoap.org/ws/2004/09/policy\" 
            xmlns:wsu=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd\" 
            xmlns:wsa=\"http://www.w3.org/2005/08/addressing\" 
            xmlns:wst=\"http://schemas.xmlsoap.org/ws/2005/02/trust\">
             <s:Header>
              <wsa:Action s:mustUnderstand=\"1\">http://schemas.xmlsoap.org/ws/2005/02/trust/RST/Issue</wsa:Action>
              <wsa:To s:mustUnderstand=\"1\">http://Passport.NET/tb</wsa:To>    
              <wsse:Security>
                <wsse:UsernameToken wsu:Id=\"devicesoftware\">
                  <wsse:Username>11#{device_name}</wsse:Username>
                  <wsse:Password>#{device_password}</wsse:Password>
                </wsse:UsernameToken>
              </wsse:Security>
            </s:Header>
            <s:Body>
              <wst:RequestSecurityToken Id=\"RST0\">
                   <wst:RequestType>http://schemas.xmlsoap.org/ws/2005/02/trust/Issue</wst:RequestType>
                   <wsp:AppliesTo>
                      <wsa:EndpointReference>
                         <wsa:Address>http://Passport.NET/tb</wsa:Address>
                      </wsa:EndpointReference>
                   </wsp:AppliesTo>
                </wst:RequestSecurityToken>
            </s:Body>
          </s:Envelope>"
          # call authorization endpoint
          res = RestClient.post(authorization_endpoint,device_token_request,:content_type => "application/soap+xml; charset=UTF-8")
          doc = Nokogiri::XML(res)
          # validate response and raise if invalid
          _is_response_valid(doc,"IssueDeviceToken")
          # get device token
          security_token_responce = doc.xpath("//S:Envelope/S:Body").children[0]
          security_token_responce.xpath("//wst:RequestedSecurityToken/*", 'wst' => 'http://schemas.xmlsoap.org/ws/2005/02/trust').to_s
      end

      # Gets a Windows Live ID RequestSecurityTokenResponse ticket for a specified user.  
      # authorization_endpoint - Authorization endpoint
      # user_name - The Windows Live ID email address for the user.
      # password - The Windows Live ID password for the user.
      # partner - sitename, i.e. crmapp.www.local-titan.com
      # policy - auth policy, i.e. MBI_SSL
      # client_id - The unique id of the client/application
      # device_token - The device token xml
      # Returns - A string that contains the Windows Live ID ticket for 
      # the supplied paramters and ticket expiration date/time
      def _get_ticket(authorization_endpoint,user_name,password,partner,policy,client_id,device_token)
        user_token_request = "<?xml version=\"1.0\"?>
          <s:Envelope 
            xmlns:s=\"http://www.w3.org/2003/05/soap-envelope\" 
            xmlns:wsse=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd\" 
            xmlns:wsp=\"http://schemas.xmlsoap.org/ws/2004/09/policy\" 
            xmlns:wsu=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd\" 
            xmlns:wsa=\"http://www.w3.org/2005/08/addressing\" 
            xmlns:wst=\"http://schemas.xmlsoap.org/ws/2005/02/trust\">
             <s:Header>
              <wsa:Action s:mustUnderstand=\"1\">http://schemas.xmlsoap.org/ws/2005/02/trust/RST/Issue</wsa:Action>
              <wsa:To s:mustUnderstand=\"1\">http://Passport.NET/tb</wsa:To>    
             <ps:AuthInfo Id=\"PPAuthInfo\" xmlns:ps=\"http://schemas.microsoft.com/LiveID/SoapServices/v1\">
                   <ps:HostingApp>#{client_id}</ps:HostingApp>
                </ps:AuthInfo>
                <wsse:Security>
                   <wsse:UsernameToken wsu:Id=\"user\">
                      <wsse:Username>#{user_name}</wsse:Username>
                      <wsse:Password>#{password}</wsse:Password>
                   </wsse:UsernameToken>
                   <wsse:BinarySecurityToken ValueType=\"urn:liveid:device\">
                     #{device_token}
                   </wsse:BinarySecurityToken>
                </wsse:Security>
            </s:Header>
            <s:Body>
              <wst:RequestSecurityToken Id=\"RST0\">
                   <wst:RequestType>http://schemas.xmlsoap.org/ws/2005/02/trust/Issue</wst:RequestType>
                   <wsp:AppliesTo>
                      <wsa:EndpointReference>
                         <wsa:Address>#{partner}</wsa:Address>
                      </wsa:EndpointReference>
                   </wsp:AppliesTo>
                   <wsp:PolicyReference URI=\"#{policy}\"/>
                </wst:RequestSecurityToken>
            </s:Body>
          </s:Envelope>"
          # call authorization endpoint
          res = RestClient.post(authorization_endpoint,user_token_request,:content_type => "application/soap+xml; charset=UTF-8")
          doc = Nokogiri::XML(res)
          # validate response and raise if invalid
          _is_response_valid(doc,"IssueTicket")
          # get ticket
          security_token_responce = doc.xpath("//S:Envelope/S:Body").children[0]
          expires = DateTime.parse(doc.xpath('//wst:Lifetime/wsu:Expires',
            {'wst' => 'http://schemas.xmlsoap.org/ws/2005/02/trust', 
             'wsu' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd'}).text)
          ticket = security_token_responce.xpath("//wst:RequestedSecurityToken/*", 'wst' => 'http://schemas.xmlsoap.org/ws/2005/02/trust')[0].text
          [CGI::escape(ticket),expires]
      end
    end
  end
end