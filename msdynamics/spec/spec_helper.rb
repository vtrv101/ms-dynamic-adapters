require 'rubygems'

# Set environment to test
ENV['RHO_ENV'] = 'test'
ROOT_PATH = File.expand_path(File.join(File.dirname(__FILE__),'..'))
Bundler.require(:default, ENV['RHO_ENV'].to_sym)

# Try to load vendor-ed rhosync, otherwise load the gem
begin
  require 'vendor/rhosync/lib/rhosync'
rescue LoadError
  require 'rhosync'
end

$:.unshift File.join(File.dirname(__FILE__), "..") # FIXME:
# Load our rhosync application
require 'application'
include Rhosync

require 'rhosync/test_methods'

module RSpec
 module Core
   module SharedExampleGroup
   private
     def ensure_shared_example_group_name_not_taken(name)
     end
   end
 end
end

$authenticated = false

shared_examples_for "SpecHelper" do
  include Rhosync::TestMethods

  before(:all) do
    unless $authenticated
      Store.db.flushdb
      credentials = File.open('spec/credentials').gets
      @test_user,@test_password = credentials ? credentials.split(',') : ['','']
      if @test_user.length > 0 and @test_password.length > 0
        puts "Performing authentication with MS Dynamic CRM instance for the user [#{@test_user}]"
        $authenticated = Application.authenticate(@test_user,@test_password,nil) 
      else
        puts "Specify test user before running these specs" unless @test_user.length > 0
        puts "Specify test user password before running these specs" unless @test_password.length > 0
      end
    end
  end
  
  before(:each) do
    # preserving auth info 
    auth_info = Application.load_auth_info(@test_user)
    Store.db.flushdb
    Application.initializer(ROOT_PATH)
    # restoring auth info in the DB
    Application.save_auth_info(@test_user,auth_info) unless auth_info.nil?
  end
end