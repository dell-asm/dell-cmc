# Copyright (C) 2014 Dell, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'racadm')
Puppet::Type.type(:chassis_settings).provide(:default, :parent=>Puppet::Provider::Racadm) do

  def chassis_name
    racadm_cmd('getchassisname')
  end
  
  def chassis_name=(name)
    racadm_cmd('setchassisname', {}, name)
  end

  def register_dns
    racadm_get_config('cfgLanNetworking', 'cfgDNSRegisterRac' )
  end
  
  def register_dns=(register)
    racadm_set_config('cfgLanNetworking', 'cfgDNSRegisterRac', enabled_bit(register) )
  end

  def dns_name
    racadm_get_config('cfgLanNetworking', 'cfgDNSRacName' )
  end

  def dns_name=(dns_name)
    racadm_set_config('cfgLanNetworking', 'cfgDNSRacName', dns_name)
  end

  def datacenter
    racadm_get_config('cfgLocation', 'cfgLocationDataCenter')
  end
  
  def datacenter=(datacenter)
    racadm_set_config('cfgLocation', 'cfgLocationDataCenter', datacenter)
  end

  def aisle
    racadm_get_config('cfgLocation', 'cfgLocationAisle')
  end
  
  def aisle=(aisle)
    racadm_set_config('cfgLocation', 'cfgLocationAisle', aisle)
  end

  def rack
    racadm_get_config('cfgLocation', 'cfgLocationRack')
  end
  
  def rack=(rack)
    racadm_set_config('cfgLocation', 'cfgLocationRack', rack)
  end

  def rackslot
    racadm_get_config('cfgLocation', 'cfgLocationRackslot')
  end
  
  def rackslot=(rackslot)
    racadm_set_config('cfgLocation', 'cfgLocationRackslot', rackslot)
  end

  def users; end
  def users=(users)
    #Start at index 2, don't want to touch the root user which is at index 1
    #clear out users beforehand
    (2..16).each do |i|
      #Setting user name to blank will reset/delete the user
      result = racadm_set_config('cfgUserAdmin', 'cfgUserAdminUserName', '""', {'i' => i})
      Puppet.err("Could not reset user at i #{i}") unless result.to_s =~ /successfully/
    end
    users.each_with_index do |user, index|
      racadm_set_user(user['username'], get_password(user['password']), user['role'], user['enabled'], index+2)
    end
  end

  #This method is only used for extending this provider, in order to add custom decryption to the password field if desired.
  def get_password=(password)
    password
  end

  def smtp_server 
    racadm_get_config('cfgRemoteHosts', 'cfgRhostsSmtpServerIpAddr')
  end

  def smtp_server=(server)
    racadm_set_config('cfgRemoteHosts', 'cfgRhostsSmtpServerIpAddr', server)
  end

  def email_destinations; end

  def email_destinations=(destinations)
    destinations.each_with_index do |destination, index|
      racadm_set_config('cfgEmailAlert', 'cfgEmailAlertEnable', 1, {'i'=>index+1})
      racadm_set_config('cfgEmailAlert', 'cfgEmailAlertAddress', destination['email'], {'i' => index+1})
      racadm_set_config('cfgEmailAlert', 'cfgEmailAlertEmailName', destination['name'], {'i' => index+1})
    end
  end

  def alert_destinations; end

  def alert_destinations=(destinations)
    destinations.each_with_index do |destination, index|
      racadm_set_config('cfgTraps', 'cfgTrapsEnable', 1, {'i'=>index+1})
      racadm_set_config('cfgTraps', 'cfgTrapsAlertDestIPAddr', destination['destinationIpAddress'], {'i' => index+1})
      racadm_set_config('cfgTraps', 'cfgTrapsCommunityName', get_community_string(destination['communityString']), {'i' => index+1})
    end
  end

  #This method is only used for extending this provider, in order to add custom decryption to the community string field if desired.
  def get_community_string(string)
    string
  end
  
  def redundancy_policy
    racadm_get_config('cfgChassisPower', 'cfgChassisRedundancyPolicy')
  end

  def redundancy_policy=(policy_number)
    racadm_set_config('cfgChassisPower', 'cfgChassisRedundancyPolicy', policy_number)
  end

  def perf_over_redundancy
    racadm_get_config('cfgChassisPower', 'cfgChassisPerformanceOverRedundancy')
  end

  def perf_over_redundancy=(perf_over_redundancy)
    racadm_set_config('cfgChassisPower', 'cfgChassisPerformanceOverRedundancy', perf_over_redundancy)
  end

  def dynamic_power_engage
    racadm_get_config('cfgChassisPower', 'cfgChassisPerformanceOverRedundancy')
  end

  def dynamic_power_engage=(engage_enable)
    racadm_set_config('cfgChassisPower', 'cfgChassisDynamicPSUEngagementEnable', engage_enable)
  end

  def ntp_enabled
    racadm_get_config('cfgRemoteHosts', 'cfgRhostsNtpEnable')
  end

  # -g cfgRemoteHotes -o cfgRhostsNtpServer<index from 1) address
  def ntp_enabled=(ntp_enabled)
    racadm_set_config('cfgRemoteHosts', 'cfgRhostsNtpEnable', ntp_enabled)
  end

  def ntp_preferred
    racadm_get_config('cfgRemoteHosts', 'cfgRhostsNtpServer1')
  end

  def ntp_preferred=(ntp_preferred)
    racadm_set_config('cfgRemoteHosts', 'cfgRhostsNtpServer1', ntp_preferred)
  end

  def ntp_secondary
    racadm_get_config('cfgRemoteHosts', 'cfgRhostsNtpServer2')
  end

  def ntp_secondary=(ntp_secondary)
    racadm_set_config('cfgRemoteHosts', 'cfgRhostsNtpServer2', ntp_secondary)
  end

  def time_zone
    output = racadm_cmd('getractime', {'z'=> ''})
    output.rpartition('timezone:').last.strip
  end

  #setractime -z zone
  def time_zone=(time_zone)
    racadm_cmd('setractime', {'z' => time_zone})
  end

  def power_cap_suffix
    case resource[:power_cap_type].to_s.downcase
      when "watts"
        ""
      when "percentage"
        "Percent"
      when "btu/h"
        "BTU"
    end
  end

  def power_cap
    val = racadm_get_config('cfgChassisPower', "cfgChassisPowerCap#{power_cap_suffix}")
    val.split(" ").first
  end

  def power_cap=(power_cap)
    racadm_set_config('cfgChassisPower', "cfgChassisPowerCap#{power_cap_suffix}", power_cap)
  end

end
