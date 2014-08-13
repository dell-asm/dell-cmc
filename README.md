# racadm

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with racadm](#setup)
    * [What racadm affects](#what-racadm-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with racadm](#beginning-with-racadm)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

_This is a work in progress!_
racadm is a puppet module for running racadm commands on network devices.  Extending Puppet's "Device" capability.

## Module Description

This module works by ssh'ing into a network appliance and using the racadm command along with defined paramaters to configure the appliance.

Currently, the only supported usage is for checking and updating the cmc firmware.

## Setup

### Setup Requirements **OPTIONAL**

* This module requires that the net-ssh gem be installed and available to the puppet user.

### Beginning with racadm

The following class would create an appropriate configuration to run the puppet device command on device.

```puppet
    $hostname = 'localhost'
    racadm::config { $hostname:
      username => 'root',
      password => 'letmeinnow',
      port     => '22',
      url      => $hostname,  #defaults to name
      target   => "${::settings::confdir}/device/${hostname}",
    }
    
    racadm_fw_update { 'update':
      ensure => present,
      fw_version => '0.1.4',
    }
```

## Usage


## Reference


## Limitations



## Development


