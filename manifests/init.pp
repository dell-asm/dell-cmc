# == Class: chassism1000e
#
# Full description of class chassism1000e here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { chassism1000e:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2014 Your name here, unless otherwise noted.
#
class chassism1000e (
  $owner    = $chassism1000e::params::owner,
  $group    = $chassism1000e::params::group,
  $provider = $chassism1000e::params::provider,
  $mode     = $chassism1000e::params::mode
) inherits chassism1000e::params {

  if !defined(File["${settings::confdir}/device"]) {
    file { "${settings::confdir}/device":
      ensure => directory,
      owner  => $owner,
      group  => $group,
      mode   => $mode,
    }
  }

  package { 'net-ssh':
    ensure   => present,
    provider => $provider,
  }
}
