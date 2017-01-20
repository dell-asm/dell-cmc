require "spec_helper"
require "discovery"
include RSpec::Mocks::ExampleMethods

describe Chassis::Discovery do

  let(:chassis_discovery) { Chassis::Discovery.new({:chassis => "172.17.131.41",
                                                    :credential_id => "ff808081531a089801531a0a5b540007"
                                                   }) }

  it "should be a Chassis::Discovery" do
    expect(chassis_discovery).to be_a(Chassis::Discovery)
  end

  it "should start discovery on ASM" do
    ASM::Api = double("ASM::Api", :sign => "{\"jobName\" : \"Job-eb346c6c-620c-4281-bf45-d2c587261057\"}")
    chassis_discovery.java_resource_adapter_framework_discovery.should == "Job-eb346c6c-620c-4281-bf45-d2c587261057"
    chassis_discovery.discovery_job_name.should == "Job-eb346c6c-620c-4281-bf45-d2c587261057"
  end

  it "should return nil when checking job status and there is not a discovery job name" do
    chassis_discovery.job_status.should be_nil
  end

  it "should return a job status" do
    ASM::Api = double("ASM::Api", :sign => "\"IN_PROGRESS\"")
    chassis_discovery.discovery_job_name = "Job-eb346c6c-620c-4281-bf45-d2c587261057"
    chassis_discovery.job_status.should == "\"IN_PROGRESS\""
  end

  it "should wait for discovery to complete" do
    ASM::Api = double("ASM::Api", :sign => "\"SUCCESSFUL\"")
    chassis_discovery.discovery_job_name = "Job-eb346c6c-620c-4281-bf45-d2c587261057"
    chassis_discovery.wait_for_complete.should == 0
  end

  it "should return the refId from the discovery result" do
    discovery_xml = File.read(File.expand_path("spec/fixtures/discovery_result.xml"))
    ASM::Api = double("ASM::Api", :sign => discovery_xml)
    chassis_discovery.discovery_job_name = "Job-eb346c6c-620c-4281-bf45-d2c587261057"
    chassis_discovery.get_discovered_devices.should == "ff8080815471c3b50154a0cb562233d7"
  end

  it "should use the reference id to get device information" do
    ASM::Api = double("ASM::Api", :sign => "json")
    chassis_discovery.reference_id = "ff8080815471c3b50154a0cb562233d7"
    chassis_discovery.asm_manager_server.should == "json"
  end
end
