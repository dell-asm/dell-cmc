require 'puppet'
$LOAD_PATH << '/opt/asm-deployer/lib'
require 'asm/api'

module Chassis
  class Discovery

    def initialize(opt)
      @chassis = opt[:chassis]
      @port = opt[:port]
      @username = opt[:username]
      @password = opt[:password]
      @timeout = opt[:timeout]
      @community_string = opt[:community_string]
      @credential_id = opt[:credential_id]
      @output = opt[:output]
      @discovery_job_name = nil
      @reference_id = nil
    end

    attr_accessor :chassis, :port, :username, :password, :timeout, :community_string, :credential_id, :output,
                  :discovery_job_name, :reference_id

    def asm_manager_chassis_discovery_request
      result = ASM::Api::sign() {
        RestClient.post("http://localhost:9080/AsmManager/ChassisDiscoveryRequest",
                        {:deviceType => "chassis",
                         :displayName => "discovery of chassis:#{SecureRandom.uuid}",
                         :refId => SecureRandom.uuid,
                         :refType => "discoveryIpRefType",
                         :credentialID => credential_id,
                         :ipAddress => chassis
                        }.to_json,
                        :accept => :json,
                        :content_type => :json)
      }
      if result
        @reference_id = JSON.parse(result)["refId"]
      else
        puts "There was not a response from the ASM /AsmManager/ChassisDiscoveryRequest"
      end
    end

    def java_resource_adapter_framework_discovery
      result = ASM::Api::sign() {
        RestClient.post("http://localhost:9080/JRAF/discovery",
                        {:refId => reference_id,
                         :refType => "discoveryIpRefType",
                         :displayName => "discovery of chassis:#{SecureRandom.uuid}",
                         :deviceType => "chassis",
                         :credentialId => credential_id,
                         :ipAddress => chassis
                        }.to_json,
                        :accept => :json,
                        :content_type => :json)
      }
      @discovery_job_name = JSON.parse(result)["jobName"]
    end

    def wait_for_complete
      start_time=DateTime.now
      until job_status.include?("SUCCESSFUL") do
        sleep 10
      end
      end_time=DateTime.now
      elapsed_seconds = ((end_time - start_time) * 24 * 60 * 60).to_i
      elapsed_seconds
    end

    def job_status
      ASM::Api::sign { RestClient.get("http://localhost:9080/JRAF/jobhistory/#{discovery_job_name}/status", :accept => :json) } if discovery_job_name
    end

    def get_discovered_devices
      discovered_device_xml = ASM::Api::sign { RestClient.get("http://localhost:9080/JRAF/discovery/#{discovery_job_name}/devices", :accept => :xml) } if discovery_job_name
      @reference_id = Nokogiri::XML(discovered_device_xml).at_css("refId").text
    end

    def asm_manager_server
      puts json = ASM::Api::sign { RestClient.get("http://localhost:9080/AsmManager/Chassis/#{reference_id}", :accept => :json) } if reference_id
      json
    end

  end
end

