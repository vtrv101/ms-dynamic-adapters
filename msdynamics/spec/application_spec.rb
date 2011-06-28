require File.join(File.dirname(__FILE__),'spec_helper')

describe "Application" do
  it_should_behave_like "SpecHelper" do
    it "should test app" do 
      puts 'app test'
    end
  end
end