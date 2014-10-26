require 'puppet/util/network_device/transport/ssh'

#This class is only used for a workaround where setting networking on IOMs does not persist
#Required to SSH into switch to save config. 
class Puppet::Util::SshIom < Puppet::Util::NetworkDevice::Transport::Ssh

  def initialize(host, user, password)
    @host = host
    @user = user
    @password = password
    @default_prompt = /[#>]\s?\z/n
    @verbose = true
    super()
  end

end
