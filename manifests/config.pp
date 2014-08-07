# Defined Resource Type: racadm::config
#
#   This defined resource type will create an racadm device configuration file
#     to be used with Puppet.
#
# Parameters:
#
# [*username*] - The username used to connect to the racadm device
# [*password*] - The password used to connect to the racadm device
# [*url*]      - The url to the racadm device. DO NOT INCLUDE https://
# [*target*]   - The path to the racadm configuration file we are creating
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
#  racadm::config { 'bigip':
#    username  => 'admin',
#    password  => 'password',
#    url       => 'racadm.puppetlabs.lan',
#    target    => '/etc/puppetlabs/puppet/device/bigip.conf
#  }
#

define racadm::config(
  $username = 'root',
  $password = 'calvin',
  $url      = $name,
  $target   = "${settings::confdir}/defice/${name}.conf"
  ) {
  
  include racadm::params
  
  $owner = $racadm::params::owner
  $group = $racadm::params::group
  $mode  = $racadm::params::mode

  file { $target:
    ensure  => present,
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    content => template('racadm/config.erb'),
  }
}
