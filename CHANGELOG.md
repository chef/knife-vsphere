# knife-vsphere changelog

<!-- latest_release 4.1.2 -->
## [v4.1.2](https://github.com/chef/knife-vsphere/tree/v4.1.2) (2020-02-11)

#### Merged Pull Requests
- Further speedup the plugin by lazy loading deps [#498](https://github.com/chef/knife-vsphere/pull/498) ([tas50](https://github.com/tas50))
<!-- latest_release -->

<!-- release_rollup since=4.1.1 -->
### Changes not yet released to rubygems.org

#### Merged Pull Requests
- Further speedup the plugin by lazy loading deps [#498](https://github.com/chef/knife-vsphere/pull/498) ([tas50](https://github.com/tas50)) <!-- 4.1.2 -->
<!-- release_rollup -->

<!-- latest_stable_release -->
## [v4.1.1](https://github.com/chef/knife-vsphere/tree/v4.1.1) (2020-01-31)

#### Merged Pull Requests
- Move around more requires to speed up knife [#497](https://github.com/chef/knife-vsphere/pull/497) ([tas50](https://github.com/tas50))
<!-- latest_stable_release -->

## [v4.1.0](https://github.com/chef/knife-vsphere/tree/v4.1.0) (2020-01-30)

#### Merged Pull Requests
- Update README.md [#493](https://github.com/chef/knife-vsphere/pull/493) ([bby-bishopclark](https://github.com/bby-bishopclark))
- Lazy load the rbvmomi dep to speedup knife [#496](https://github.com/chef/knife-vsphere/pull/496) ([tas50](https://github.com/tas50))

## [v4.0.8](https://github.com/chef/knife-vsphere/tree/v4.0.8) (2019-12-21)

#### Merged Pull Requests
- Substitute require for require_relative [#492](https://github.com/chef/knife-vsphere/pull/492) ([tas50](https://github.com/tas50))

## [v4.0.7](https://github.com/chef/knife-vsphere/tree/v4.0.7) (2019-11-05)

#### Merged Pull Requests
- Allow for the latest rbvmomi [#489](https://github.com/chef/knife-vsphere/pull/489) ([tas50](https://github.com/tas50))
- Update filesize requirement from ~&gt; 0.1.1 to &gt;= 0.1.1, &lt; 0.3.0 [#487](https://github.com/chef/knife-vsphere/pull/487) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))

## [v4.0.5](https://github.com/chef/knife-vsphere/tree/v4.0.5) (2019-10-31)

#### Merged Pull Requests
- Add a reference to our wiki article on templates [#482](https://github.com/chef/knife-vsphere/pull/482) ([swalberg](https://github.com/swalberg))
- Make sure we ship the license file with the gem [#485](https://github.com/chef/knife-vsphere/pull/485) ([tas50](https://github.com/tas50))

## [v4.0.3](https://github.com/chef/knife-vsphere/tree/v4.0.3) (2019-10-10)

#### Merged Pull Requests
- trivial update to vm-state options [#478](https://github.com/chef/knife-vsphere/pull/478) ([bby-bishopclark](https://github.com/bby-bishopclark))
- Support suspend and suspended for state [#481](https://github.com/chef/knife-vsphere/pull/481) ([swalberg](https://github.com/swalberg))

## [v4.0.1](https://github.com/chef/knife-vsphere/tree/v4.0.1) (2019-09-16)

#### Merged Pull Requests
- Support for Chef-15 [#474](https://github.com/chef/knife-vsphere/pull/474) ([samshinde](https://github.com/samshinde))
- Bump version to 4 for major release with Chef 15 support [#475](https://github.com/chef/knife-vsphere/pull/475) ([btm](https://github.com/btm))
- Update README and github templates for OSS Best Practices [#476](https://github.com/chef/knife-vsphere/pull/476) ([samshinde](https://github.com/samshinde))

## [v3.0.1](https://github.com/chef/knife-vsphere/tree/v3.0.1) (2019-07-10)

#### Merged Pull Requests
- Avoid a few more frozen constant warnings [#473](https://github.com/chef/knife-vsphere/pull/473) ([tas50](https://github.com/tas50))

## [v3.0.0](https://github.com/chef/knife-vsphere/tree/v3.0.0) (2019-07-05)

#### Merged Pull Requests
-  Add a buildkite test queue and update github codeowners [#471](https://github.com/chef/knife-vsphere/pull/471) ([tas50](https://github.com/tas50))
- Require Ruby 2.4 or later &amp; test PRs in buildkite [#472](https://github.com/chef/knife-vsphere/pull/472) ([tas50](https://github.com/tas50))

## [v2.1.6](https://github.com/chef/knife-vsphere/tree/v2.1.6) (2019-07-04)

#### Merged Pull Requests
- Add rspec dev dep and bump chefstyle to the latest [#470](https://github.com/chef/knife-vsphere/pull/470) ([tas50](https://github.com/tas50))

## [v2.1.5](https://github.com/chef/knife-vsphere/tree/v2.1.5) (2019-07-04)

#### Merged Pull Requests
- Find host through the API rather than iterating [#464](https://github.com/chef/knife-vsphere/pull/464) ([swalberg](https://github.com/swalberg))
- Bootstrap: add bootstrap_template remove old opts [#466](https://github.com/chef/knife-vsphere/pull/466) ([swalberg](https://github.com/swalberg))
- Fix handling of program args in vsphere vm execute. [#468](https://github.com/chef/knife-vsphere/pull/468) ([dsopscak](https://github.com/dsopscak))
- Loosen the knife-windows dep to allow 3.x [#469](https://github.com/chef/knife-vsphere/pull/469) ([tas50](https://github.com/tas50))

2.1.1   swalberg   - Allow vsphere vm config to handle multiple settings per
                     invocation
									 - Kill off vsphere vm query
									 - Update vsphere vm show to show multiple items and use
									   ui.output
									 - vsphere vm execute handles multiple args and uses faster
									   find

2.1.0   swalberg   - Update find and clone to use SearchHelper

BREAKING CHANGE: knife vsphere vm find has some subtle changes:
* Previously you'd need to specify a pool to search within. Now it searches
  everything from the root folder
* The enclosing folder name used to come by default, now you need --short-path

2.0.5   swalberg   - Better search. Such fast. Much wow
                   - Fixed all knife vsphere vm * commands to use search
                     helper with folder option
                   - Updated vm network list to be a bit faster
                   - Updated template list to use the search helper
                   - Remove dead code.

2.0.4   nammiesgal - Refactored display_node method in vsphere_vm_snapshot.rb to output
                     list of snapshots in a tree hierarchy that can be output in various
                     formats using ui.output.
                   - Add additional snapshot information to the tree hierarchy
                   - Add cpu and memory hot add enabled flags to vsphere_vm_find.rb
        swalberg   - Introduce a faster way of finding a VM to some commands

2.0.3   swalberg   - If the node exists prior to clone, move to bootstrap

2.0.2   nammiesgal - Add snapshot creation timestamp to snapshot listing.
                   - Add option "--snapshot-descr DESCR" to allow users to add a 
                     description when creating a snapshot.
        swalberg   - doc updates
                   - Handle the nicsettingmismatch error on clone
        benpoliquin- Fix misleading output in vm delete

2.0.1   petermccool - Add datastore output to disk list
        mheidenr    - Fix vm migrate and refactor
        scotthain   - Error checking when looking up address in clone
        tas50       - Require a more recent Chef release
        mattkasa    - Fix issue where --cdomain is ignored on Windows
        jjasghar    - Update Jenkinsfile

2.0.0   jjasghar   - YARD DOCS!
                   - Jenkinsfile to let ppl test against a live env
                   - Templates for issues and PRs
        swalberg   - Defer looking up the hostname (fixes #374)
                   - Windows license is options (fixes #373)
                   - Move `vsphere vm find` to Chef output format
1.2.26  petericebear - Set CPUs per socket and reserved memory

1.2.25  warroyo    - more formatting, exit codes

1.2.24  dhgwilliam - add support for filtering networks by dvswitch
        warroyo    - add formatted output and ability to filter on pool/cluster
                   - add proper exit codes
        scotthain  - README corrections

1.2.23  mheidenr - re-add accidentally reverted fix from '22

1.2.22  warroyo  - Use presenters for cluster, host, datastore listings 
                   Means -f json and -f yaml work!
        zachsmorgan  - stop escaping regexps in datastore maxfree
        swalberg - Clone to specific host (thanks to @jjashgar for help)
        mheidenr - check if config[:customization_ips] is still the default NO_IPS

1.2.21  coda4096 - Set MAC and NIC type in vm network add

1.2.20  coda4096 - Delete a NIC
                 - List networks on a VM
        swalberg - Cleanup of mounting CD

1.2.19  coda4096 - Enable VNC on a VM
                 - Add a NIC to an existing VM <3 <3

1.2.18  omgroves - knife vsphere vm network set (change nic)
        swalberg - support tagging during bootstrap
                 - provide sane error message for common windows clone failure

1.2.17  martinmosegaard - Add --node-ssl-verify-mode
        jjasghar - doc improvements
        swalberg - bootstrap testing
                 - doc improvements

1.2.16  swalberg - Somehow a typo from refactoring got out, sorry

1.2.15  swalberg - Add --bootstrap-msi-url (#289, #272)
                 - Refactoring clone to add tests
                 - --disable-customization now makes a nil customization
                   unless used with --cspec. Its use is to restrict the
                   customizations done to the VM
                 - Doc updates
                 - Travis fixes (remove Gemfile.lock, bump Ruby)
                 - Final fix(?) for that mac and ip interaction
                 - Refactor LocationSpec creation and fix thin-provision
        jjasghar - Doc updates
                 - Pass sudo password to Boostrap when needed
 martinmosegaard - VM clone with resource pool and linked clone (

1.2.14  swalberg - Bugfix from 1.2.12

1.2.13  kozmikyak - Bugfix from previous
        swalberg  - Bugfix from previous

1.2.12  kozmikyak - Support for specifying the switch and MAC of VM
        mkherlakian - Can list all of a VM's IPS and their associated networks
        vancluever - Bugfix for waiting for IP
        swalberg - Convert docs to MD

1.2.11  rhass    - Add clone/bootstrap option to allow choosing NIC when
                   more than one NIC is configured in the source template
                   or VM.
                 - Add clone/bootsrap option to force the use of IPv4 addresses

1.2.10  swalberg - Fix get_config to allow falsey values

1.2.9   swalberg - Bump knife-windows to fix gem conflict with em-winrm
                 - Handle missing VM case in vmdk add
        dliscomb - Fix casting problem in sysprep-timeout

1.2.8   swalberg - Add find, quiesce, memory to snapshot h/t tcicone
                 - Use supplied hostname for sysprep h/t paulherbosch

1.2.7   swalberg - ignore create dir errors to get around #213

1.2.6   mheidenr - vsphere vm disk extend
                 - comment cleanup
        swalberg - vsphere vm disk list
1.2.5   stmos    - Fix problems in vm clone when passing multiple vlans
        rhadoo   - Add vm find option
                 - Add a --wait option when creating a snapshot
        swalberg - Change the two "query" commands to use "show", with a warning
        brok02   - Adds the missing --only-folders option to vm list
                 - --disable-customization actually disables customization now

1.2.4   swalberg - Fix dependencies h/t adamedx
        kbrowns  - Add --folders-only for vm list
                   markastemplate fix to not require a folder
                   customization fixes
        nbrisebois mount CDRoms
                   datastore file up/download
        tim95030 - correct default port for winrm

1.2.3   mheidenr - Set identity in spec when not using --cspec

1.2.2   nbrisebois - Filter max free datastore by vlan
        mheidenr   - Another fix from 1.2.0

1.2.1   dzabel   - Hotfix for 1.2.0

1.2.0   tim95030 - Bootstrap Windows nodes with winrm
        mheidenr - Monitor VSphere events to know when sysprep is done

1.1.2   Learath  - Improve the way we find a host to clone to

1.1.1   DennisBP - Possibility to generate random VMNAMEs
        swalberg - Fix some arguments that used vshere
                 - Add a Gemfile to the repository
                 - Added create vlan command

1.0.1
        swalberg - Support cloning VM with a DHCP address
                 - Allow the admin to configure multiple VLANs
                 - Add instructions on how to use the master branch
        troyready - Add obfuscated password storage
        DennisBP - Fix for base64 encoded password
                 - Fix for chef secret-file option
                 - Fix for "pool list" output
                 - Updated gemspec file
                 - Optimized some code snippets
                 - Rubocop support
                 - New "cluster list" command to get a list of available clusters from the vcenter
        vancluever - add vault options for bootstrapping


1.0
        rhadoo - add hosts list option
        rhadoo - add vm networking on/off support
        rhadoo - add vm migrate support
        ezrapagel - by default, show hosts from all pools
        ezrapagel - report back resource pools during pool list
        ezrapagel - include new folder list command
        ezrapagel - refactored vm list to not display templates, folders are separate command
        andrewfraley - fix - vm clone finds VMs in subfolders
        cmeil - fix -snapshot could not be found if a sibling snapshot contains child snapshots
        andrewfraley -  fix - datastorecluster works with subfolders
        andrewfraley -  vm clone cspec works with all Linux distros
        thorduri - environment option for vm clone
        coremedia - allows modifying properties in vm.
        keymon - fix - create VirtualEthernetCardNetworkBackingInfo is created when attaching to standard switch
        tcicone -Added thin provisioning to the clone and move option
        mheidenr - list ratio between assigned virtual CPUs and physical CPUs on all hosts

1.0.0.pre.3 *
        jrosen - added ability to clone into template
        bellpeterm - allow :source_vm to be set in knife.rb
        jeremymv2 - cplugin example in readme
        mheidenr - vm clone can now clone and customize windows vms
        chenhaiq - fix undef method when cloning

1.0.0.pre.2 *
        bdupras - added property subcommand
        bdupras - fixed prerelease naming -pre to .pre
        bdupras - tidy up Rakefile

1.0-pre *
        mheidenr - added option to select a datatstorecluster in vm clone
        mheidenr - function mark as template added
        mheidenr - documented vm state command, added recursive option for vm state
        valldeck - customization plugin call is called to early

0.9.9 * going to have to rev this!
        andrewfraley - fixed vm config issue with not finding VMs in subfolders
        terracor - use first network card instead of "Network Adapter 1"
        tim95030 - moved datacenter param to capital D to avoid conflicts with distro
        tim95030 - added option to allow linked clones

0.9.8 * chenhaiq - fixed bug in datastore max free
        andrewfraley - vsphere pool query command to query resource pools and host clusters
        micolous - formatting fix
        andrewfraley - Added support for VMs in subfolders when doing vm query
        mheidenr - datastore cluster max free space commands

0.9.6 * mheidenr - added command to get the datastore with the most free space
        mheidenr - moved REGEX parameter to maxfree command
        bdupras - added command vm move
        b-dean - change how the datacenter is found
        dcondomitti - add proxy support

0.9.5 * bdupras - added command vm config PROPERTY VALUE
  mdkent -  handle parent class of ClusterComputeResource
  alastair - update readme to reflect behavior of vm.destroy_task and --purge option

0.9.0 * bdupras - adds optional --shutdown parameter for guest os
                - added vm query VMNAME QUERY sub-command to query the named properties
                - modified vm state --wait-port to use vm.guest.ipAddress
                - added secret-file option for bootstrapping
        kirtfitzpatrick - removed the default distro parameter

0.8.1 * Bethany Erskine - specify chef-client log level when using --bootstrap

0.8.0 * Adrian Stanila added --annotation option (fixes #39)
        Ian Delahorne - VM state in vsphere vm list
        Yvonne Lam - vm clone` does not accept --vmname option.

0.7.0 * James White - added a ton of LUN selection support, corresponding automatic
          LSILogic adapter creation

0.6.0 * Greg Swallow - fixed a rake break.
        Mark Malone - added vm snapshot support!

0.5.0 * kirtfitzpatrick - Added plugin support to vm clone;
        Brian Flad - Added --wait-port option to vm state command, Add command to add VMDK to VM
        Troy Ready - add password query prompt

0.4.0 * Bethany Erskine - add support for --json-attribute option, json string
        for use w/ --bootstrap
        Adrian Stanila - option to disable customizations

0.3.0 * Ian Delahorne - added support for tools script execution
  jcam - bootstrap dhcp nodes

0.2.3 * leeor - Fix --cvlan handling when VC is not using a distributed switch
  jcam - Added pool list command, updated readme, fixed chef version constraint

0.2.2 * jcam - add pool list subcommand, adjust gemspec to support chef 10.x.x

0.2.1 * robharrop - update to rbvmomi 1.5.1

0.2.0 * jcam - allow defaults from subcommands, error for missing .chef with bootstrap

0.1.9 * jcam - add support for configuring options from the command line or config files

0.1.8 * add Ian Delahorne's support for showing datastores with their available size and
        capacity, bug fixes
0.1.7 * rev'd changelog/readme, formatting cleanup

0.1.6 * merged in changes from Jesse Campbell, supporting VLAN/resource
        pool/folder/data store selection, run list support, and much more

0.1.5 * support customized hostname, post-clone poweron

0.1.4 * added support for vm powerstate control

0.1.3 * added support for listing customization specs, applying during cloning

0.1.2 * support nested vm/host folders