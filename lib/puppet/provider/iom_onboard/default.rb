# Copyright (C) 2014 Dell, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'racadm')
Puppet::Type.type(:iom_onboard).provide(:default, :parent=>Puppet::Provider::Racadm) do

  class ExecModeTerminationError < Exception; end

  def credential; end

  def credential=(credential)
    resource[:slots].each do |slot|
      next if is_passthrough(slot)
      pw = get_password(credential)
      comm_string = get_community_string(credential)
      output = racadm_set_root_creds(get_password(credential), 'switch',slot, get_community_string(credential))
      if output =~ /ERROR/
        Puppet.info("Connecting directly to switch's serial port to set user...")
        check_disable_bmp_mode(slot)
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
    #Bypass configuration for pass-through and IOM in stacking mode with "Member role"
    switch_info.match(/10GBE ETHERNET MODULE|PASS-THROUGH|Member/)
  end

  def network_type
    resource[:network_type] != :existing ? nil : :existing
  end

  def network_type=(network_type)
    networks = Hash[resource[:slots].zip(resource[:networks])]
    set_networks("switch", network_type, networks)
    resource[:slots].each do |slot|
      send_iom_commands(slot, ['write mem'])
    end
  end

  def check_disable_bmp_mode(slot)
    Puppet.debug("Disabling the BMP mode and ensure reload-type is configured to normal")
    send_iom_commands(slot,['\r', '\r', 'A\r', 'yes'],true)
    commands = [ 'configure', 'reload-type normal-reload', 'exit', 'write mem']
    send_iom_commands(slot,commands)
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
    Puppet.info("Set root credentials and community string directly on switch-#{slot}")
  end

  def send_iom_commands(slot, cmds=[], skip_privilege_mode=false)
    attempt = 1
    iom_prompt = /^.*[#>].*\z|Password:|Press RETURN/i
    iom_prompt = /.*/ if skip_privilege_mode
    out = connection.command("connect switch-#{slot}", :prompt=>/Escape|console in use/)
    if out =~ /console in use/
      Puppet.err("Could not connect to switch-#{slot}. Serial console is in use.")
    else
      begin
        out = enter_privileged_exec(iom_prompt, slot) if skip_privilege_mode == false
        cmds.each do |cmd|
          ( skip_privilege_mode and cmd.match(/A/)) ? new_iom_prompt = /yes|>|#|.+/ : new_iom_prompt = iom_prompt
          out = connection.command(cmd, :prompt=>new_iom_prompt)
          if out =~ /RETURN/
            raise(ExecModeTerminationError, 'CMC kicked out of enabled exec mode')
          end
          sleep(5) if skip_privilege_mode == true
        end
        #Terminates the console, returns connection back to cmc
        connection.command("\c|")
      rescue ExecModeTerminationError
        raise('CMC terminated enable exec mode, could not configure correctly.') if attempt > 4
        Puppet.debug('CMC terminated enable exec mode.  Retrying previous commands...')
        attempt += 1
        retry
      end
    end
  end

  #Sometimes entering privileged exec mode fails for some reason.  This method will just retry it a couple times.
  def enter_privileged_exec(prompt, slot)
    Puppet.debug("Inside enter_privileged_exec")
    begin
      attempts ||= 1
      #Need to carriage return to get things moving
      connection.command("\r", :prompt=>prompt, :timeout => 10)
      out = connection.command("enable", :prompt=>prompt)
      if out =~ /Password:/
        Puppet.err("Could not connect to switch-#{slot}.  Enable password should not be set")
      elsif out =~ /RETURN/ || out !~ /#/
        raise 'Could not enter privileged exec mode.'
      end
    rescue Exception => e
      Puppet.debug("Could not enter privileged exec mode on switch-#{slot}.  Retrying...")
      if attempts > 3
        Puppet.err("Leaving serial console for switch-#{slot} because couldn't enter privileged exec mode. Some configuration may be skipped")
      else
        attempts += 1
        sleep 1
        retry
      end
    end
  end
end
