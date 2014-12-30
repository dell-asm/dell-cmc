# Copyright (C) 2014 Dell, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'racadm')
Puppet::Type.type(:iom_onboard).provide(:default, :parent=>Puppet::Provider::Racadm) do

  def credential; end

  def credential=(credential)
    resource[:slots].each do |slot|
      next if is_passthrough(slot)
      pw = get_password(credential)
      comm_string = get_community_string(credential)
      output = racadm_set_root_creds(get_password(credential), 'switch',slot, get_community_string(credential))
      if output =~ /ERROR/
        Puppet.info("Connecting directly to switch's serial port to set user...")
        set_mxl_root(slot, pw, comm_string)
      end
    end
  end

  def is_passthrough(slot)
    output = racadm_cmd('getioinfo', {}).flatten
    switch_info = ''
    output.each do |switch_out|
      switch_info = ( switch_out.scan(/^Switch-#{slot}.*?$/m) || []).flatten.first
      break if !switch_info.nil?
    end
    switch_info.match(/10GBE ETHERNET MODULE|PASS-THROUGH/)
  end

  def network_type
    resource[:network_type] != :existing ? nil : :existing
  end

  def network_type=(network_type)
    networks = Hash[resource[:slots].zip(resource[:networks])]
    racadm_set_addressing("switch", network_type, networks)
    resource[:slots].each do |slot|
      send_iom_commands(slot, ['write mem'])
    end
  end

  def set_mxl_root(slot, password, community_string)
    commands = 
    [
      'configure',
      "username root password #{password}",
      "snmp-server community #{community_string} ro",
      'exit',
      'write mem'
    ]
    send_iom_commands(slot, commands)
  end

  def send_iom_commands(slot, cmds=[])
    iom_prompt = /^.*[#>].*\z/
    out = connection.command("connect switch-#{slot}", :prompt=>/Escape|console in use/)
    if out =~ /console in use/
      Puppet.err("Could not connect to switch-#{slot} to set root credentials.  Serial console is in use.")
    else
      #Need to carriage return to get things moving
      out = connection.command("\r", :prompt=>iom_prompt)
      out = connection.command("enable", :prompt=>iom_prompt)
      cmds.each do |cmd|
        out = connection.command(cmd, :prompt=>iom_prompt)
      end
      #Terminates the console, returns connection back to cmc
      connection.command("\c|")
      Puppet.info("Set root credentials and community string directly on switch-#{slot}")
    end
  end
end
