# Copyright (C) 2014 Dell, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'racadm')
Puppet::Type.type(:iom_onboard).provide(:default, :parent=>Puppet::Provider::Racadm) do

  def credential; end

  def credential=(credential)
    racadm_set_root_creds(get_password(credential), 'switch', get_community_string(credential))
  end

  def network_type
    resource[:network_type] != :existing ? nil : :existing
  end

  def network_type=(network_type)
    networks = Hash[resource[:slots].zip(resource[:networks])]
    racadm_set_addressing("switch", network_type, networks)
    resource[:slots].each do |slot|
      save_iom_config(slot)
    end
  end

  #Work around the fact that using racadm setniccfg will not set a persistent config on the switch between reboots
  def save_iom_config(slot)
    require 'puppet/util/ssh_iom'
    password = get_password(@resource[:credential])
    i = 0
    begin
      ip = racadm_cmd('getniccfg', {'m'=>"switch-#{slot}"}, '', false)['IP Address']
      ssh = Puppet::Util::SshIom.new(ip, 'root', password)
      ssh.connect
    rescue => e
      i += 1
      if i < 4
        Puppet.debug("Switch at #{ip} not ready.  Retrying in 30 seconds...")
        sleep 30
        retry
      else
        raise e
      end
    end
    out = ssh.command('write mem')
    Puppet.info("write mem result: #{out}")
    ssh.close
  end
end
