Puppet::Type.newtype(:racadm_get) do
  desc "racadm util to get info"
  ensurable
  resource[:provider] = :racadm
  newparam(:get) do 
    desc "Get info"
    ensurable
  end
#  newparam(:output) do
#    desc "Output info to destination"
#  end
end
