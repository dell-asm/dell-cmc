Puppet::Type.newtype(:cmc_onboard) do
  desc "cmc util to setup cmc root user and networking if given"

  apply_to_device

  newparam(:name, :namevar => true) do
    desc "The cert name of the chassis"
  end

  newproperty(:credential) do
    desc "Used to lookup the credentials that are used to set up the root user"
  end
  
  newparam(:network) do
    desc "The network object that gives the information needed to set up static networking for CMC"
  end

  newproperty(:network_type) do
    desc "The type of network to setup on the cmc"
    newvalue(:static)
    newvalue(:existing)
  end

end