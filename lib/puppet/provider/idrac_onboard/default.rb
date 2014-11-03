# Copyright (C) 2014 Dell, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'racadm')
Puppet::Type.type(:idrac_onboard).provide(:default, :parent=>Puppet::Provider::Racadm) do

  def credential; end

  def credential=(credential)
    resource[:slots].each do |slot|
      racadm_set_root_creds(get_password(credential), 'server', slot)
    end
  end

  def network_type
    resource[:network_type] != :existing ? nil : :existing
  end

  def network_type=(network_type)
    networks = Hash[resource[:slots].zip(resource[:networks])]
    racadm_set_addressing("server", network_type, networks)
  end
end
