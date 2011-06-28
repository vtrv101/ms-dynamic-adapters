require File.join(File.dirname(__FILE__),'spec_helper')

describe "Application" do
  it_should_behave_like "SpecHelper" do
    it "should authenticate" do 
      Application.authenticate(@test_user,@test_password,nil).should be_true
    end
  end
end