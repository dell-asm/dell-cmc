#
# This class is only here to ensure existing code specifically pointing to device type chassism1000e doesn't break
# Module now refers to more generic name instead of specifically to chassism1000e.
#

require 'puppet/util/network_device/cmc/transport'

module Puppet::Util::NetworkDevice::Chassism1000e
  class Transport <  Puppet::Util::NetworkDevice::Cmc::Transport
  end
end
