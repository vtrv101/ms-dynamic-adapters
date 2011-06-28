require 'lib/msdynamics'

class Application < Rhosync::Base
  class << self
    def authenticate(username,password,session)
      begin
        # TODO: handle exceptions
        # From time to time Win Live doesn't respond or returns 400 (Bad Request); 
        # we probably should retry in such cases  
        wlid_ticket, wlid_expires = 
          MSDynamics::WlidService.get_ticket(username,password)
        puts "wlid_ticket" + wlid_ticket
        puts "wlid_expires" + wlid_expires.to_s
        crm_service_url, crm_ticket, crm_ticket_expires, user_organization = 
          MSDynamics::DiscoveryService.get_crm_ticket("rhomobileinc.crm.dynamics.com",wlid_ticket)
        puts "crm_service_url: " + crm_service_url
        puts "crm_ticket:" + crm_ticket
        puts "crm_ticket_expires: " + crm_ticket_expires.to_s
        puts "user_organization: " + user_organization
        #Store.set_data("#{username}-")
      rescue Exception => ex
        warn "Can't authenticate user #{username}: " + ex.inspect
        return false
      end
      true
    end
    
    # Add hooks for application startup here
    # Don't forget to call super at the end!
    def initializer(path)
      super
    end
    
    # Calling super here returns rack tempfile path:
    # i.e. /var/folders/J4/J4wGJ-r6H7S313GEZ-Xx5E+++TI
    # Note: This tempfile is removed when server stops or crashes...
    # See http://rack.rubyforge.org/doc/Multipart.html for more info
    # 
    # Override this by creating a copy of the file somewhere
    # and returning the path to that file (then don't call super!):
    # i.e. /mnt/myimages/soccer.png
    def store_blob(object,field_name,blob)
      super #=> returns blob[:tempfile]
    end
  end
end

Application.initializer(ROOT_PATH)