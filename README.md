# Chassism1000e

#### Table of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Setup - The basics of getting started with racadm](#setup)
    * [Setup requirements](#setup-requirements)
    * [Beginning with racadm](#beginning-with-racadm)
4. [Usage](#usage)
5. [Reference](#reference)
5. [Limitations](#limitations)
6. [Development](#development)

## Overview

_This is a work in progress!_
Chassism1000e is a puppet module for managing the Dell m1000e chassis.  Extending Puppet's "Device" capability.

## Module Description

This module works by ssh'ing into a network appliance and using the racadm command along with defined paramaters to configure the appliance.

Currently, the only supported usage is for checking and updating the cmc firmware.

## Setup

### Setup Requirements

* This module requires that the net-ssh gem be installed and available to the puppet user.

### Beginning with racadm

The following class would create an appropriate configuration to run the puppet device command on device.

```puppet
    $hostname = 'localhost'
    chassism1000e::config { $hostname:
      username => 'root',
      password => 'letmeinnow',
      port     => '22',
      url      => $hostname,  #defaults to name
      target   => "${::settings::confdir}/device/${hostname}",
    }
    
    racadm_fw_update { 'update':
      firmwares =>
        version => '0.4.1',
        path    => 'path/to/binary'
      }
    }
```

## Usage


## Reference


## Limitations



## Development


