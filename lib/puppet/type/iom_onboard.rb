Puppet::Type.newtype(:iom_onboard) do
  desc "Util to setup networking and new creds on ioms through CMC racadm"

  apply_to_device

  newparam(:name, :namevar => true) do
    desc "The cert name of the chassis"
  end

  newproperty(:credential) do
    desc "Used to lookup the credentials that are used to set up the root user"
  end
  
  newparam(:slots) do
    desc "Array of all the slots with switches in them"
    munge do |value|
      #Needs to be an array of values so it can be zipped up later with networks.  
      value.is_a?(Array) ? value : [value]
    end
  end

  newparam(:networks) do
    desc "A listing of the network objects containing the necessary information for setting the iom networks"
    munge do |value|
      #Needs to be an array of values so it can be zipped up later with slots.  
      value.is_a?(Array) ? value : [value]
    end
  end

  newproperty(:network_type) do
    desc "The type of network to setup on the switches"
    newvalue(:static)
    newvalue(:existing)
    newvalue(:dhcp)
  end

end