 require 'json'

 Puppet::Type.newtype(:chassis_settings) do
  desc "Used for setting up miscellaneous chassis settings"

  apply_to_device

  newparam(:name, :namevar => true) do
    desc "The cert name of the chassis"
  end

  newproperty(:chassis_name) do
    desc "The name assigned to the chassis"
  end

  #register_dns must come before dns_name
  #Puppet evaluates properties in the order they are defined here
  newproperty(:register_dns) do
    desc "Whether to register the CMC name on the DNS"
  end
  
  newproperty(:dns_name) do
    desc "The DNS name to register the chassis with"
  end

  newproperty(:datacenter) do
    desc "The datacenter name for this chassis"
  end

  newproperty(:aisle) do
    desc "The aisle name for this chassis"
  end

  newproperty(:rack) do
    desc "The rack name for this chassis"
  end

  newproperty(:rackslot) do
    desc "The rackslot name for this chassis"
  end

  #go through list of users, replace data on existing users.   For , remove data, disable user
  newproperty(:users) do
    desc "A hash of local users to set through the cmc"
    munge do |value|
      JSON.parse(value)
    end
  end

  newproperty(:alert_destinations) do
    desc ""
    munge do |value|
      JSON.parse(value)
    end
  end

  newproperty(:smtp_server) do
    desc ""
  end

  # racadm config -g cfgEmailAlert -o cfgEmailAlertEnable -i <1-4>
  #• Set the destination email address.
  #racadm config -g cfgEmailAlert -o cfgEmailAlertAddress -i <1-4>
  newproperty(:email_destinations) do
    desc ""
    munge do |value|
      JSON.parse(value)
    end
  end

  #-g cfgChassisPower -o cfgChassisRedundancyPolicy
  newproperty(:redundancy_policy) do
    desc ""
    munge do |value|
      case value.downcase
      when "none"
        '0'
      when "grid"
        '1'
      when "powersupply"
        '2'
      else
        raise "Invalid redundancy policy"
      end
    end
  end

  #-g cfgChassisPower -o cfgChassisPerformanceOverRedundancy
  newproperty(:perf_over_redundancy) do
    desc ""
    munge do |value|
      if(value == :true )
      '1'
    elsif(value==:false )
      '0'
    end
    end
  end

  #-g cfgChassisPower -o cfgChassisDynamicPSUEngagementEnable
  newproperty(:dynamic_power_engage) do
    desc ""
    munge do |value|
      if(value == :true )
      '1'
    elsif(value==:false )
      '0'
    end
    end
  end

  # -g cfgRemoteHotes -o cfgRhostsNtpServer<index from 1) address
  #Is this necessary?  I can probably assume that if a ntp server is passed in, they should be enabled
  newproperty(:ntp_enabled) do
    desc ""
    munge do |value|
      if(value == :true )
        '1'
      elsif(value==:false )
        '0'
      end
    end
  end

  newproperty(:ntp_preferred) do
    desc ""
  end

  newproperty(:ntp_secondary) do 
    desc ""
  end

  #setractime -z zone
  newproperty(:time_zone) do
    desc ""
  end
  #-g cfgChassisPower -o cfgChassisPowerCap(<empty>/BTU/Percent) 
  #power_cap_type will have either watts/btu/or %
  newproperty(:power_cap) do
    desc ""
    munge do |value|
      if value == '0.0' || value == '0'
        value = nil
      end
      value
    end
  end

  newparam(:power_cap_type) do
    desc ""
  end

end