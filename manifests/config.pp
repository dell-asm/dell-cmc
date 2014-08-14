# Defined Resource Type: chassism1000e::config
#
#   This defined resource type will create an chassism1000e device configuration file
#     to be used with Puppet.
#
# Parameters:
#
# [*username*] - The username used to connect to the chassism1000e device
# [*password*] - The password used to connect to the chassism1000e device
# [*url*]      - The url to the chassism1000e device. DO NOT INCLUDE https://
# [*target*]   - The path to the chassism1000e configuration file we are creating
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
#  chassism1000e::config { 'bigip':
#    username  => 'admin',
#    password  => 'password',
#    url       => 'chassism1000e.puppetlabs.lan',
#    target    => '/etc/puppetlabs/puppet/device/bigip.conf
#  }
#

define chassism1000e::config(
  $username = 'root',
  $password = 'root',
  $url      = $name,
  $port     = '22',
  $target   = "${settings::confdir}/defice/${name}.conf"
  ) {
  
  include chassism1000e::params
  
  $owner = $chassism1000e::params::owner
  $group = $chassism1000e::params::group
  $mode  = $chassism1000e::params::mode

  file { $target:
    ensure  => present,
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    content => template('chassism1000e/config.erb'),
  }
}
