class Puppet::Provider::Racadm <  Puppet::Provider
  @@role_permissions = {"Administrator" => "0x00000fff"}


  def transport
    @device ||= Puppet::Util::NetworkDevice.current
    raise Puppet::Error, "Puppet::Util::NetworkDevice::Chassism1000e: device not initialized #{caller.join("\n")}" unless @device
  end

  def ssh
    @ssh ||= Puppet::Util::NetworkDevice.current.transport.connect
  end

  def racadm_simple_cmd(subcommand, flags={})
    cmd = "racadm #{subcommand}"
    append_flags(cmd, flags)
    output = ssh.exec!(cmd)
    Puppet.info("racadm #{subcommand} result: #{output}")
    parse_output_values(output)
  end

  def racadm_set_config(group, config_object, param_values, flags={})
    param_string = param_values.is_a?(Array) ? param_values.join(" ") : param_values
    cmd = "racadm config -g #{group} -o #{config_object} #{param_string}"
    append_flags(cmd, flags)
    output = ssh.exec!(cmd)
    Puppet.info("racadm_set_config result: #{output}")
    parse_output_values(output)
  end

  def racadm_get_config(group=nil, config_object=nil, flags=nil)
    cmd = "racadm getconfig"
    if(group)
      cmd << " -g #{group}"
    end
    if(config_object)
      cmd << " -o #{config_object}"
    end
    append_flags(cmd, flags)
    parse_output_values(ssh.exec!(cmd))
  end

  def racadm_set_niccfg(module_name, type, ip_addr=nil, ip_mask=nil, gateway=nil)
    cmd = "racadm setniccfg -m #{module_name}"
    network_settings = ""
    if(type == :dhcp)
      network_settings = ' -d'
    elsif(type == :static)
      network_settings = " -s #{ip_addr} #{ip_mask} #{gateway}"
    end
    cmd << network_settings
    output = ssh.exec!(cmd)
    Puppet.info("racadm_set_niccfg result for #{module_name}: #{output}")
    output
  end

  def racadm_set_user(name, password, role, index)
    permission_bits = @@role_permissions[role]
    name_result = racadm_set_config('cfgUserAdmin', 'cfgUserAdminUserName', name, {'i' => index})
    password_result = racadm_set_config('cfgUserAdmin', 'cfgUserAdminPassword', password, {'i' => index})
    Puppet.err("Could not set username for user at index #{index}") unless password_result.to_s =~ /successfully/
    role_result = racadm_set_config('cfgUserAdmin', 'cfgUserAdminPrivilege', permission_bits, {'i' => index})
    Puppet.err("Could not set privileges for user at index  #{index}") unless role_result.to_s =~ /successfully/
    enable_result = racadm_set_config('cfgUserAdmin', 'cfgUserAdminEnable', 1, {'i' => index})
    Puppet.err("Could not enable user #{index} at index") unless enable_result.to_s =~ /successfully/
  end

  def racadm_set_root_creds(password, type)
    flags = {
      'u' => 'root',
      'p' => "'#{password}'",
      'a' => type
    }
    output = racadm_simple_cmd('deploy', flags)
    Puppet.info("racadm_set_creds result: #{output}")
  end

  def get_password(credential)
    return credential
  end

  def racadm_set_addressing(module_type, network_type, networks)
    networks.each do |slot, network|
      if(network_type == :dhcp)
        output = racadm_set_niccfg("#{module_type}-#{slot}", network_type)
      elsif(network_type == :static)
        network_obj = network['staticNetworkConfiguration']
        output = racadm_set_niccfg("#{module_type}-#{slot}",network_type, network_obj['ipAddress'], network_obj['subnet'], network_obj['gateway'])
      end
    end
    if(network_type == :dhcp)
      wait_for_dhcp(module_type, networks)
    end
  end

  def wait_for_dhcp(module_type, networks)
    networks.each do |slot, value|
      checks = 1
      #The wait should be pretty short if at all for the slots other than the first one checked
      name = "#{module_type}-#{slot}"
      loop do
        output = racadm_simple_cmd('getniccfg', {'m' => "#{name}"})
        break if checks > 10 || (output['DHCP Enabled'] = '1' && output['IP Address'] != '0.0.0.0')
        checks += 1
        sleep 30
        Puppet.info("Waiting for DHCP address for #{name}")
      end
      if(checks == 30)
        raise "Timed out waiting for DHCP address for #{name}"
      end
    end
  end

  def append_flags(cmd, flag_hash)
    flag_hash.keys.each do |flag|
      cmd << " -#{flag} #{flag_hash[flag]}"
    end
    cmd
  end

  def parse_output_values(output)
    lines = output.split("\n")
    #If we can split by =, it's a return with key/values we can parse.  Otherwise, just return the output as is split by new line character
    if(lines.first.split("=").size > 1)
      Hash[lines.map{|str| str.split("=")}.collect{|line|
        key = line[0].strip
        #Sometimes, the first line starts with # symbol.  Just clean it out if it does so we return a good hash
        if(key.start_with?('#'))
          key = key[1..-1].strip
        end
        value = line[1].nil? ? "" : line[1].strip 
        [key, value]
        }]
    else
      lines
    end
  end
end