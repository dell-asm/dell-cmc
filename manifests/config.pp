# Defined Resource Type: cmc::config
#
#   This defined resource type will create an cmc device configuration file
#     to be used with Puppet.
#
# Parameters:
#
# [*username*] - The username used to connect to the cmc device
# [*password*] - The password used to connect to the cmc device
# [*url*]      - The url to the cmc device. DO NOT INCLUDE https://
# [*target*]   - The path to the cmc configuration file we are creating
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
#  cmc::config { 'bigip':
#    username  => 'admin',
#    password  => 'password',
#    url       => 'cmc.puppetlabs.lan',
#    target    => '/etc/puppetlabs/puppet/device/bigip.conf
#  }
#

define cmc::config(
  $username = 'root',
  $password = 'root',
  $url      = $name,
  $port     = '22',
  $target   = "${settings::confdir}/defice/${name}.conf"
  ) {
  include cmc::params
  $owner = $cmc::params::owner
  $group = $cmc::params::group
  $mode  = $cmc::params::mode

  file { $target:
    ensure  => present,
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    content => template('cmc/config.erb'),
  }
}
