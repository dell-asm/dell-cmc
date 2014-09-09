# Copyright (C) 2014 Dell, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'racadm')
Puppet::Type.type(:cmc_onboard).provide(:default, :parent=>Puppet::Provider::Racadm) do

  def credential; end

  def credential=(credential)
    password = get_password(credential)
    password_result = racadm_set_config('cfgUserAdmin', 'cfgUserAdminPassword', password, {'i' => 1})
    Puppet.err("Could not set password for root user") unless password_result.to_s =~ /successfully/
  end

  def network_type
    resource[:network_type] != :existing ? nil : :existing
  end

  #With how puppet properties works, this should only be called when network_type is not existing
  #This will also be called very last of everything, so no IP issues should come about from changing it
  def network_type=(network_type)
    network_obj = resource[:network]["staticNetworkConfiguration"]
    racadm_set_niccfg("chassis", :static, network_obj['ipAddress'], network_obj['subnet'], network_obj['gateway'])
    wait_for_ip_change(network_obj['ipAddress'])
  end

  def wait_for_ip_change(new_ip)
    require 'asm/cipher'
    require 'open3'
    creds = ASM::Cipher.decrypt_credential(resource[:credential])
    result = Hashie::Mash.new
    checks = 1
    loop do
      cmd = "sudo wsman identify -h #{new_ip} -P 443 -u root -p #{creds.password} -c dummy.cert -y basic -V -v"
      Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
        stdin.close
        result.stdout      = stdout.read
        result.stderr      = stderr.read
        result.pid         = wait_thr[:pid]
        result.exit_status = wait_thr.value.exitstatus
      end
      #Exit code will always be 0, so we break when stderr is empty
      break if checks > 10 || result.stderr.empty?
      checks += 1
      sleep 30
      Puppet.info("Waiting for static address for chassis ${resource[:name]}...")
    end
    if(checks > 10)
      raise("Timed out waiting for chassis static IP address to be set")
    end
  end
end
