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

shared_examples_for "SpecHelper" do
  include Rhosync::TestMethods
  
  before(:each) do
    Store.db.flushdb
    Application.initializer(ROOT_PATH)
  end  
end