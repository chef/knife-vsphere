# knife vSphere

[![Gem Version](https://badge.fury.io/rb/knife-vsphere.svg)](https://rubygems.org/gems/knife-vsphere)
[![Build status](https://badge.buildkite.com/b68210c9f6436b2275b9365b0fe9ccdce80bd41a79f62424ac.svg?branch=master)](https://buildkite.com/chef-oss/chef-knife-vsphere-master-verify)
[![Inline docs](http://inch-ci.org/github/chef/knife-vsphere.svg?branch=master)](http://inch-ci.org/github/chef/knife-vsphere)

**Umbrella Project**: [Knife](https://github.com/chef/chef-oss-practices/blob/master/projects/knife.md)

 **Project State**: [Active](https://github.com/chef/chef-oss-practices/blob/master/repo-management/repo-states.md#active)

 **Issues [Response Time Maximum](https://github.com/chef/chef-oss-practices/blob/master/repo-management/repo-states.md)**: 14 days

 **Pull Request [Response Time Maximum](https://github.com/chef/chef-oss-practices/blob/master/repo-management/repo-states.md)**: 14 days

Please refer to the [CHANGELOG](CHANGELOG) for version history and known issues.

* Documentation: <https://github.com/chef/knife-vsphere/blob/master/README.md>
* Source: <http://github.com/chef/knife-vsphere/tree/master>
* Issues: <https://github.com/chef/knife-vsphere/issues>
* Slack: sign up: https://code.vmware.com/slack/ slack channel: #chef
* Mailing list: <https://discourse.chef.io/>

## Installation

This gem ships as part of Chef Workstation so the easiest way to get started is to install Chef Workstation

If you're using bundler as part of a project, add `knife` and `knife-vsphere` to your `Gemfile`:

```ruby
gem 'knife'
gem 'knife-vsphere
```

Depending on your system's configuration, you may need to run this command with root privileges.

## Configuration

For initial development, the plugin targets all communication at a vCenter
instance rather than at specific hosts. Only named user authentication is
currently supported; you can add the credentials to your `knife.rb` file:

```ruby
knife[:vsphere_host] = "vcenter-hostname"
knife[:vsphere_user] = "privileged username" # Domain logins may need to be "user@domain.com"
knife[:vsphere_pass] = "your password"       # or %Q(mypasswordwithfunnycharacters)
knife[:vsphere_dc] = "your-datacenter"
```

The vSphere password can also be stored in a base64 encoded version (to
visually obfuscate it) by prepending 'base64:' to your encoded password. For
example:

```ruby
knife[:vsphere_pass] = "base64:Zm9vYmFyCg=="
```

If you get the following error, you may need to disable SSL certificate
checking:

```
ERROR: OpenSSL::SSL::SSLError: SSL_connect returned=1 errno=0
state=SSLv3 read server certificate B: certificate verify failed
```

```ruby
knife[:vsphere_insecure] = true
```

Credentials can also be specified on the command line for multiple vSphere
servers/data centers, or see [dealing with multiple datacenters](https://github.com/chef/knife-vsphere/wiki/Dealing-with-multiple-datacenters).

### vCenter Permissions

You need the following permissions (at minimum) on your user to be able to use `knife-vsphere`.

* Datastore
    * Allocate space :ballot_box_with_check:
    * Browse datastore :ballot_box_with_check:
* Host
    * Local Operations
         * Create virtual machine :ballot_box_with_check:
         * Delete virtual machine :ballot_box_with_check:
         * Manage user groups :ballot_box_with_check:
         * Reconfigure virtual machine :ballot_box_with_check:
 * Network
    * Assign Network :ballot_box_with_check:
 * Resource
    * Assign virtual machine to resource pool :ballot_box_with_check:
 * Virtual Machine :ballot_box_with_check:


## Description:

This is an Chef Knife plugin to interact with VMware's vSphere. This plugin
currently supports the following:

### Listings:

* VMs
* Folders
* Templates
* Datastores
* VLANs (currently requires distributed vswitch)
* Resource Pools and Clusters
* Customization Specifications
* Hosts in a Pool or Cluster
* Network cards and VLANs for a VM


### VM Operations:

* Power on/off
* Clone (with optional chef bootstrap and run list)
* Delete
* VMDK addition
* Migrate
* Add network
* Connect/disconnect network
* Delete network
* Change network
* Enable VNC remote console


### Clone-specific customization options (for Linux guests):

* Destination folder
* CPU core count
* CPU cores per socket
* Memory size
* Memory reservation
* DNS settings
* Hostname / Domain name
* IP addresses / default gateway
* vlan (currently requires distributed vswitch)
* datastore
* resource pool

Note: For Windows guests we can run FIELDS

## Basic Examples:

Here are some basic usage examples to help get you started.

- This clones from a VMware template and bootstraps chef into it. It uses
the generic DHCP options.

```bash
$ knife vsphere vm clone MACHINENAME --template TEMPLATENAME --bootstrap --cips dhcp
```

- This clones a vm from a VMware template bootstraps chef, then uses a [Customization template](https://pubs.vmware.com/vsphere-55/index.jsp?topic=%2Fcom.vmware.vsphere.vm_admin.doc%2FGUID-EB5F090E-723C-4470-B640-50B35D1EC016.html)
called "SPEC" to help bootstrap. Also calls a different SSH user and Password.

```bash
$ knife vsphere vm clone MACHINENAME --template TEMPLATENAME --bootstrap --cips dhcp \
  --cspec SPEC --connection-user USER --connection-password PASSWORD
```

Note: add a `-f FOLDERNAME` if you put your `--template` in someplace other then
root folder, and use `--dest-folder FOLDERNAME` if you want your VM created in
`FOLDERNAME` rather than the root.

A full basic example of cloning from a folder, and putting it in the "Datacenter Root"
directory is the following:

```bash
$ knife vsphere vm clone MACHINENAME --template TEMPLATENAME -f LOCATIONOFTEMPLATE \
  --bootstrap --start --cips dhcp --dest-folder /
```

- Listing the available VMware templates

```bash
$ knife vsphere template list
Template Name: ubuntu16-template
$ knife vsphere template list -f FOLDERNAME
Template Name: centos7-template
```

- Deleting a machine.

```bash
$ knife vsphere vm delete MACHINENAME (-P will remove from the chef server)
```

# Subcommands

This plugin provides the following Knife subcommands.  Specific command
options can be found by invoking the subcommand with a `--help` flag

## `knife vsphere vm list`

Enumerates the Virtual Machines registered in the target datacenter. Only name
is currently displayed.

```bash
-r, --recursive    - Recurse down through sub-folders to the specified folder
--only-folders     - Print only folder names. Implies recursive
```

## `knife vsphere vm find`

Search for Virtual Machines matching criteria and display selected fields

CRITERIA:
Note that _all_ criteria must be satisfied for the VM to be returned

```bash
--match-ip IP                match ip
--match-name VMNAME          match name
--match-os OS                match os
--match-tools TOOLSSTATE     match tools state
--powered-off                Show only stopped machines
--powered-on                 Show only started machines
```

FIELDS:
```bash
--alarms                     show alarm status
--cpu                        Show cpu
--cpu-hot-add-enabled        Show cpu hot add enabled flag
--esx-disk                   Show esx disks
--full-path                  Show full folder path to the VM
--short-path                 Show the enclosing folder name
--hostname                   show hostname
--host_name                  Show name of the VM's host
--ip                         Show primary ip
--networks                   Show all networks and IPs
--os                         Show os details
--os-disks                   Show os disks
--ram                        Show ram
--memory-hot-add-enabled     Show memory hot add enabled flag
--snapshots                  Show snapshots
--tools                      show tools status
```

Example:

```bash
$ knife vsphere vm find --snapshots --full-path --cpu --ram --esx-disk \
    --os-disk --os --match-name my_machine_1 --alarms --tools --ip --ips \
    --match-ip 123 --match-tools toolsOk
```

## `knife vsphere vm state VMNAME`

Manage power state of a virtual machine, aka turn it off and on

```bash
-s STATE, --state STATE    - The power state to transition the VM into; one of on|off|suspend|reboot
-w PORT, --wait-port PORT  - Wait for VM to be accessible on a port
-g, --shutdown             - Guest OS shutdown (format: -s off -g)
-r, --recursive            - Recurse down through sub-folders to the specified folder to find the VM
```

## `knife vsphere pool list`

Enumerates the Resource Pools and Clusters registered in the target
datacenter.

## `knife vsphere template list`

Enumerates the VM Templates registered in the target datacenter. Only name is
currently displayed.

```bash
-f FOLDER       - Look inside the designated folder, default is the root folder
```

## `knife vsphere customization list`

Enumerates the customization specifications registered in the target
datacenter. Only name is currently displayed.

## `knife vsphere vm clone`

Clones an existing VM template into a new VM instance, optionally applying an
existing customization specification.  If customization arguments such as
`--chost` and `--cdomain` are specified, or if the customization specification
fetched from vSphere is considered, a default customization specification will
be attempted.

* For windows, a sysprep based unattended customization in
workgroup mode will be attempted (host name being the VM name unless otherwise
specified).

* For Linux, a fixed named customization using the vmname as the
host name unless otherwise specified.

This command has many options which which to customize your VM. The most important part of this is the initial template. We have some guidance on [how to make a template](https://github.com/chef/knife-vsphere/wiki/Making-a-template-for-cloning)

### Chef bootstrap options

These options alter the way that your VM will be bootstrapped with Chef after it is created. It is not necessary
to bootstrap the VM, but at the very least `--bootstrap` is required to do so.
```bash
--bootstrap - Bootstrap the VM after cloning. Implies --start
--bootstrap-ipv4 - Force using an IPv4 address when a NIC has both IPv4 and IPv6 addresses.
--bootstrap-msi-url URL - Location of the Chef Client MSI if not default from chef.io
--bootstrap-nic INTEGER - Network interface to use when multiple NICs are defined on a template.
--bootstrap-proxy PROXY_URL - The proxy server for the node being bootstrapped
--bootstrap-vault-file VAULT_FILE - A JSON file with a list of vault(s) and item(s) to be updated
--bootstrap-vault-item VAULT_ITEM - A single vault and item to update as "vault:item"
--bootstrap-vault-json VAULT_JSON - A JSON string with the vault(s) and item(s) to be updated
--bootstrap-version VERSION - The version of Chef to install
--fqdn SERVER_FQDN - Fully qualified hostname for bootstrapping
--hint HINT_NAME[=HINT_FILE] Specify Ohai Hint to be set on the bootstrap target.  Use multiple --hint options to specify multiple hints.
--ssh-identity-file IDENTITY_FILE - SSH identity file used for authentication
--json-attributes - A JSON string to be added to the first run of chef-client
--node-name NAME - The Chef node name for your new node
--ssh-verify-host-key - Verify host key. Default is 'always'. Available options are 'always' ,'accept_new accept_new_or_local_tunnel' and  'never'
--node-ssl-verify-mode [peer|none] - Whether or not to verify the SSL cert for all HTTPS requests
--prerelease - Install the pre-release chef gems
--run-list RUN_LIST - Comma separated list of roles/recipes to apply
--secret-file SECRET_FILE - A file containing the secret key to use to encrypt data bag item values
--connection-password PASSWORD - SSH password / winrm password
--connection-port PORT - SSH port / winrm port
--connection-user USERNAME - SSH username / winrm username
--sysprep_timeout TIMEOUT - Wait TIMEOUT seconds for sysprep event before continuing with bootstrap
--winrm-authentication-protocol AUTHENTICATION_PROTOCOL. The authentication protocol used during WinRM communication. The supported protocols are basic,negotiate,kerberos. Default is 'negotiate'.
--winrm-codepage Codepage    The codepage to use for the winrm cmd shell
--winrm-shell SHELL          The WinRM shell type. Valid choices are [cmd, powershell, elevated]. 'elevated' runs powershell in a scheduled task
--winrm-ssl-verify-mode SSL_VERIFY_MODE   The WinRM peer verification mode. Valid choices are [verify_peer, verify_none]
--winrm-ssl  User ssl WinRM transport type
--tags TAG1,TAG2 - Tag the node with the given list of tags
```

### Customization options

These options are related to the customization of the VM by the vSphere agent. They include hardware settings and networking.
```bash
--ccpu CUST_CPU_COUNT - Number of CPUs
--ccorespersocket CUST_CPU_CORES_PER_SOCKET - Number of CPU Cores per Socket
--cdomain CUST_DOMAIN - Domain name for customization
--cgw CUST_GW - CIDR IP of gateway for customization
--cdnsips CUST_DNS_IPS - Comma-delimited list of DNS IP addresses
--cdnssuffix CUST_DNS_SUFFIXES - Comma-delimited list of DNS search suffixes
--chostname CUST_HOSTNAME - Unqualified hostname for customization
--cips CUST_IPS - Comma-delimited list of CIDR IPs for customization, or *dhcp* to configure that interface to use DHCP
--cmacs CUST_MACS - Comma-delimited list of MAC addresses, or *auto* to configure that interface to use automatically generated MAC address
--cplugin CUST_PLUGIN_PATH - Path to plugin that implements KnifeVspherePlugin.customize_clone_spec and/or KnifeVspherePlugin.reconfig_vm
--cplugin-data CUST_PLUGIN_DATA - String of data to pass to the plugin.  Use any format you wish.
--cram CUST_MEMORY_GB - Gigabytes of RAM
--cram_reservation CUST_MEMORY_RESERVATION_GB - Gigabytes of RAM
--cspec CUST_SPEC - The name of any customization specifications that are defined in vCenter to apply
--ctz CUST_TIMEZONE - Timezone in valid 'Area/Location' format
--cvlan CUST_VLANS - Comma-delimited list of VLAN names for the network adapters to join
--disable-customization - By default customizations will be applied to the customization specification (see below).  Disable these convention with this switch (default value is `false`)
--random-vmname - Creates a random VMNAME starts with vm-XXXXXXXX
--random-vmname-prefix - Change the VMNAME prefix
```

### VMware options

These options alter the way the VM is created, such as to decide where it is placed.
```bash
--datastore STORE    - The datastore into which to put the cloned VM
--datastorecluster STORE - The datastorecluster into which to put the cloned VM
--dest-folder FOLDER - The folder into which to put the cloned VM
--resource-pool POOL|CLUSTER - The resource pool into which to put the cloned VM. Also accepts a cluster name.
--start - Start the VM after cloning.
--sw-uuid SWITCH_UUIDS - Comma-delimited list of virtual switch UUIDs to attach to the network adapters, or *auto* to automatically assign virtual switch
--template TEMPLATE - The source VM / Template to clone from
```

### Examples

```bash
$ knife vsphere vm clone NewNode --template UbuntuTemplate --cspec StaticSpec \
    --cips 192.168.0.99/24,192.168.1.99/24 \
    --chostname NODENAME --cdomain NODEDOMAIN
```

The customization specification defaults can be disabled using the
`--disable-customization true` switch. If you specify a `--cspec` with this option,
that spec will still be applied.

NOTE: if you are specifying a `--cspec` and the cloning process appears to not
be properly applying the spec as defined on vSphere, consider using
`--disable-customization true` as the conventions described above could be
erroneously interfering with the spec as defined on vSphere.

Customization specifications can also be specified in code using the `--cplugin`
and/or `--cplugin-data` arguments.  See the _plugins_ section for examples.

The `--bootstrap-vault-*` options can be used to send `chef-vault` items to be
updated during the hand-off to `knife bootstrap`.

Example using `--bootstrap-vault-json`:

```bash
$  knife vsphere vm clone NewNode UbuntuTemplate --cspec StaticSpec \
    --cips 192.168.0.99/24,192.168.1.99/24 \
    --chostname NODENAME --cdomain NODEDOMAIN \
    --start true --bootstrap true \
    --bootstrap-vault-json '{"passwords":"default","appvault":"credentials"}'
```
## `knife vsphere vm show VMNAME PROPERTY (PROPERTY)`

Shows one or more properties of the VM.

See "http://pubs.vmware.com/vi3/sdk/ReferenceGuide/vim.VirtualMachine.html" for allowed values.

Please note that this command starts at the vm object, where the corresponding `knife vsphere vm config` command
focuses entirely on a customization specification. This gives you more flexibility in what you can query, but means
you need to do some translations if you want to read old values and make a change. For example, you would query
`config.hardware.numCPU` with this command but set `numCPUs`.

Examples:

```bash
knife vsphere vm show myvirtualmachine config.hardware.memoryMB config.hardware.numCPU -F json
```

## `knife vsphere vm config VMNAME PROPERTY VALUE (PROPERTY VALUE)`

Sets a vSphere property (or series of properties), such as CPU or disk, on a VM

See "http://pubs.vmware.com/vi3/sdk/ReferenceGuide/vim.vm.ConfigSpec.html"
          for allowed PROPERTY values (any property of type xs:string or numeric is supported)."

Examples:

```bash
$ knife vsphere vm config myvirtualmachine memoryMB 4096
```

## `knife vsphere vm toolsconfig VMNAME PROPERTY VALUE`

```bash
--empty           - allows clearing string properties
```

Sets properties in tools property. See
"https://www.vmware.com/support/developer/vc-sdk/visdk25pubs/ReferenceGuide/vim.vm.ToolsConfigInfo.html"
for available properties and types.

Examples:

```bash
$ knife vsphere vm toolsconfig myvirtualmachine syncTimeWithHost false
$ knife vsphere vm toolsconfig myvirtualmachine pendingCustomization -e
```

## `knife vsphere vm delete NAME`

Deletes an existing VM, removing it from vSphere inventory and deleting from
disk, optionally deleting it from Chef as well.

```bash
--purge|-P        - Delete the client and node from Chef as well
-N                - Specify the name of the node and client to delete if it differs from NAME (requires -P)
```

## `knife vsphere vm snapshot VMNAME`

Manages the snapshots for an existing VM, allowing for creation, removal, and
reverting of snapshots.

```bash
--list            - List the current tree of snapshots and include snapshot creation timestamp
--create SNAPSHOT - Create a new snapshot off of the current snapshot
--remove SNAPSHOT - Remove a named snapshot.
--revert SNAPSHOT - Revert to a named snapshot.
--revert-current  - Revert to current snapshot.
--start           - Starts the VM after a successful revert
--wait            - Wait for creation/removal to complete rather than returning immediately
--find            - Find the VM instead of specifying the folder with -F
--dump-memory     - Dump the memory when creating the snapshot (default: false)
--quiesce         - Quiesce the VM before snapshotting (default: false)
--snapshot-descr DESCR - Include a description when creating a snapshot
```

## `knife vsphere vm cdrom`

```bash
--datastore DATASTORE - Datastore the image is stored in
--iso                 - Path and filename of the ISO
--attach              - Attach the iso immediately
--disconnect          - Disconnect any iso currently attached
--recursive           - Search for the VM recursively
--folder              - Search for the VM in the specified folder
--on_boot BOOL        - Set the Attach On Boot Boolean
```

## `knife vsphere vm disk extend`

```bash
--diskname DISKNAME - The name of the disk that will be extended (use when vm has multiple disks)
```

Note: SIZE is in kilobytes

## `knife vsphere vm disk list`

Lists the disks attached to VMNAME

## `knife vsphere datastore list`

Lists all known datastores with capacity and usage

## `knife vsphere datastore maxfree`

Gets the datastore with the most free space

```bash
--regex           - Pattern to match the datastore name
--vlan            - Require listed vlan available to datastore's parent
--pool            - Pool or Cluster to search for datastores in
```

## `knife vsphere datastore file`

Uploads files to a datastore and downloads files from a datastore

```bash
--upload-file       - Upload specified local file to remote
--download-file     - Download specified remote file to local
--remote-file FILE  - Remote file name and path
--local-file FILE   - Local file name and path
```

## `knife vsphere datastorecluster list`

Lists all known datastorecluster with capacity and usage

## `knife vsphere datastorecluster maxfree`

Gets the datastorecluster with the most free space

```bash
--regex           - Pattern to match the datastore name
```

## `knife vsphere vm execute VMNAME COMMAND ARGS`

Executes a program on the guest. Requires vCenter 5.0 or higher.

Command path must be absolute. For Linux guest operating systems, `/bin/bash` is
used to start the program. For Solaris guest operating systems, `/bin/bash` is
used to start the program if it exists. Otherwise `/bin/sh` is used.

Arguments are optional, and allow for redirection in Linux and Solaris.

```bash
--exec-user USERNAME - The username on the guest to execute as.
--exec-passwd PASSWD - The password for the user executing as.
--exec-dir DIRECTORY - Optional: Working directory to execute in. Will default to $HOME of user.
```

Example:
```bash
knife vsphere vm execute myvirtualmachine --exec-user root --exec-passwd 'password' -- /sbin/iptables -F
```

## `knife vsphere vm vnc set VMNAME`

Enable VNC remote console.

Required arguments:

```bash
--vnc-port PORT           -Port to run VNC on
--vnc-password PASSWORD   -Password for connecting to VNC
```

## `knife vsphere vm vmdk add VMNAME DISKSIZE_GB`

Adds VMDK to VMNAME, given a disk size in Gigabytes.

Optional arguments

```bash
--vmdk-type TYPE - VMDK type, "thick" or "thin", defaults to "thin"
```

## `knife vsphere vm markastemplate VMNAME`

Will mark the VM as a template rather than a runnable VM.
By default the search will start at the root folder.  `--folder` should be specified if
traversing should be in some other folder than the root.  Once found the VM
will be converted into a template.  This means the VM will become a template
and no longer be available as a Virtual Machine.  The name given to the
template will be the name of VM from which it was created.

## `knife vsphere hosts list --pool`

Lists all hosts in given Pool

## `knife vsphere vm migrate VMNAME`

Migrate VM to resource pool/datastore/host. Resource pool and datastore are
mandatory.

```bash
--folder FOLDER             - folder in which to search for VM
--resource-pool POOL        - destination resource pool
--dest-host HOST            - destination host (optional)
--dest-datastore DATASTORE  - destination datastore, accessible to HOST
--priority PRIORITY         - migration priority (optional, default defaultPriority )
```

## `knife vsphere vm net STATE VMNAME`

Set networking state for VMNAME by connecting/disconnecting network
interfaces. Possible states are `up` and `down`.

## `knife vsphere vm network set VMNAME NETWORKNAME`

Set NETWORKNAME on first interface of VMNAME. Works for both standard and distributed switches.

```bash
--nic INTEGER     - NIC to change (optional, default 0)

knife vsphere vm network set example1.test.com vlan123
knife vsphere vm network set example2.test.com vlan234 --nic 1
```

## `knife vsphere vm network add VMNAME NETWORKNAME`

Add a network card to a VM and connect it to a network.

```bash
--adapter-type STRING      - Adapter type eg e1000,vmxnet3
--mac-address STRING       - Adapter MAC address eg. AA:BB:CC:DD:EE:FF

```

## `knife vsphere vm network list VMNAME`

List the network cards and their VLAN that are connected to a VM.

## `knife vsphere vm network delete VMNAME NICNAME`

Delete a network card from a VM.


## `knife vsphere vm wait sysprep VMNAME`

Wait for vm finishing Sysprep

```bash
--sleep SLEEP      - The time in seconds to wait between queries for CustomizationSucceeded event. Default: 60 seconds
--timeout TIMEOUT  - The timeout in seconds before aborting. Default: 300 seconds
```

## `knife vsphere cpu ratio`

Lists the ratio between assigned virtual CPUs and physical CPUs on all hosts.

Example:

```bash
$ knife vsphere cpu ratio
Output:
### Cluster Cluster1 ###
host1.domain.com: 1.8125
host2.domain.com: 2.40625
host3.domain.com: 1.8125

### Cluster Cluster2 ###
host4.domain.com: 1.8125
host5.domain.com: 2.40625
```

## `knife vsphere vm move VMNAME`

Moves the VM to other datastores or to rename it.

```bash
--dest-name NAME      - Destination name of the VM or template
--dest-folder FOLDER  - The destination folder into which the VM or template should be moved
--datastore STORE     - The datastore into which to put the cloned VM
--thin-provision      - Indicates whether disk should be thin provisioned.
--thick-provision     - Indicates whether disk should be thick provisioned.
```

Recursively prints all the folders in the datacenter.

## `knife vsphere vm property get VMNAME PROPERTY`

Gets a vApp property on VMNAME

## `knife vsphere vm property set VMNAME PROPERTY VALUE`

Sets a vApp property on VMNAME to the given value

```bash
--ovf-environment-transport STRING  - Comma delimited string.  Configures the transports to use for properties. Supported values are: iso and com.vmware.guestInfo.
````

## `knife vsphere folder list`

Recursively prints all the folders in the datacenter.

## `knife vsphere pool show POOLNAME QUERY`

Shows information (hosts, networks, resources) about a pool/compute resource.

See \"http://pubs.vmware.com/vi3/sdk/ReferenceGuide/vim.ComputeResource.html\" for allowed QUERY values.".


## `knife vsphere vlan list`

Lists all the VLANs in the datacenter

## `knife vsphere vlan create NAME VID`

Creates a vlan (port group on a distributed virtual switch) with the given
name and VLAN ID. If you have multiple distributed switches then use the
`--switch` option to set the switch

# Developing, or using the latest code

The master version of this code may be ahead of the gem itself. If it's in
master you can generally consider it ready to use. To use master instead of
what's published on Ruby gems:

```bash
$ gem uninstall knife-vsphere
$ git clone git@github.com:chef/knife-vsphere.git # or your fork
$ cd knife-vsphere
$ rake build                                           # Take note of the version
$ gem install pkg/knife-vsphere-1.1.1.gem              # Use the version above
```

If you are doing development, then you can run the plugin out of a checked out
copy of the source:

```bash
$ bundle install # only needs to be done once
$ bundle exec knife vsphere ...
```

# Plugins

`knife-vsphere` supports some plugins, currently only for the clone operation.

Plugins let you write code to further customize the operation you are sending to vCenter.

The basic idea is that plugins expose well known methods to `knife`, which are then run at particular times.
The values returned from your methods are passed directly to vSphere.

Below are examples of the potential implementations that would be saved to an rb file and passed in the `--cplugin`
argument.

* [extend or add a disk during cloning](https://gist.github.com/warroyo/4887300cbb3bec2034650202a65fb906)
* [unattended Windows installation](https://github.com/chef/knife-vsphere/wiki/Sample-plugin-to-do-unattended-Windows-installations)

# Getting help

If the software isn't behaving the way you think, or you're having trouble
doing something, we're happy to help. Try this checklist:

*   Are you running the latest version? `gem list knife-vsphere`. You can
    always upgrade with `gem install knife-vsphere`
*   Try running the same command with `-VV` to add additional logging messages
*   Are there any errors in the vSphere console or logs?
*   Search for known issues at
    https://github.com/chef/knife-vsphere/issues


If you're still having problems, head on over to the
[issues](https://github.com/chef/knife-vsphere/issues) page and
create a new issue. Please include:
*   A description of what you are trying to do, what you are seeing
*   The version number of knife-vsphere and of vSphere itself
*   The exact command you're running and the output (sanitize anything you
    don't want public!)

# License

Authors
- Ezra Pagel <ezra@cpan.org>
- Jesse Campbell <hikeit@gmail.com>
- John Williams <john@37signals.com>
- Ian Delahorne <ian@scmventures.se>
- Bethany Erskine <bethany@paperlesspost.com>
- Adrian Stanila <adrian.stanila@sacx.net>
- Raducu Deaconu <rhadoo_io@yahoo.com>
- Leeor Aharon
- Sean Walberg <sean@ertw.com>

```
Copyright
  Copyright © 2011-2013 Ezra Pagel
  Copyright © 2015-2017 Chef Software, Inc
```

```
VMware vSphere is a trademark of VMware, Inc.
```

![Apache License](https://www.apache.org/img/asf_logo.png)

Licensed under the Apache License, Version 2.0 (the "License"); you may not
use this file except in compliance with the License. You may obtain a copy of
the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
License for the specific language governing permissions and limitations under
the License.

Software changes provided by Nicholas Brisebois at Dell SecureWorks. For more
information on Dell SecureWorks security services please browse to
http://www.secureworks.com

© Dell SecureWorks 2015
