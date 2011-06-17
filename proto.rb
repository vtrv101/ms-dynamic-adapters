require 'rubygems'
require 'uuidtools'
require 'rest-client'
require 'nokogiri'
require 'date'

require 'soap_service'
require 'wlidticket'
require 'discovery_service'
require 'crm_service'

# TODO: handle exceptions
# From time to time Win Live doesn't respond or returns 400 (Bad Request); 
# we probably should retry in such cases  
wlid_ticket, wlid_expires = 
  MSDynamics::WlidService.get_ticket("vlad@rhomobile.com","reg1ster")

puts wlid_ticket
puts wlid_expires

# crm_service_url, crm_ticket, crm_ticket_expires, user_organization = 
#   MSDynamics::DiscoveryService.get_crm_ticket("rhomobileinc.crm.dynamics.com",wlid_ticket)
# 
# # puts "crm_service_url: " + crm_service_url
# # puts "crm_ticket:" + crm_ticket
# # puts "crm_ticket_expires: " + crm_ticket_expires.to_s
# # puts "user_organization: " + user_organization
# 
# crm_service = MSDynamics::CrmService.new(crm_service_url,crm_ticket,user_organization)
# 
# user_id = crm_service.get_current_user
# puts 'user_id: ' + user_id
# 
# fullname = crm_service.get_current_user_full_name(user_id)
# puts 'user_full_name: ' + fullname
