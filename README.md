# azure-archlinux-packer

Builds, uploads, and deploys an [ArchLinux](https://www.archlinux.org/) image on Azure.

See below for [caveats](#caveats) and [TODOs](#TODO).

**NOTE**: This is *not* supported by me (Cole Mickens), Microsoft, Azure, or Arch Linux.
However, [Issues](https://github.com/colemickens/azure-archlinux-packer/issues) are welcome.


## Requirements

 * `docker` (optional, but expected by `README`, see `Makefile`)
 * `make`
 * An Azure AD ServicePrincipal with access to the subscrition


## Usage

These instructions will walk you through everything you need to create
and upload an Azure VHD and create a Virtual Machine from the image.

Following these steps will create:

  * a new Premium Storage Account
  * a new VirtualNetwork and Subnet
  * a new Network Security Group (with rules for SSH, Mosh, 9K-10K)
  * a public IP with a NIC for the VM
  * a new `Standard_F8S` VM
  * a **1TB** Premium data disk attached to the VM


### Build and Upload and Deploy the Image

0. Prepare the Environment:
   ```shell
   cp ./user.env.template ./user.env

   # edit the config and fill in the values
   vim user.env
   ```

2. Build and upload and deploy the image.
   ```shell
   make
   ```

   Alternatively, you may `make build && make upload && make deploy`.

The VHD URL will be in the `./_output` directory.


## Caveats

1. This is not supported by me (Cole Mickens).

2. This is not supported by Microsoft or Azure.

3. This is not supported by Arch Linux.

4. The `walinuxagent` in this image isn't fully functional. This can lead
   to **real issues**, such as the VM failing to resize or extensions
   failing to provision.

   In fact, it may actual simply fail to provision properly...


## TODO

1. Remove `walinuxagent` whenever Azure supports agent-less Linux.


## Advanced

### Local Mirror

The `local-mirror` directory includes a script that will run `nginx` as a reverse, caching proxy in front of some Arch Linux mirrors.
Make sure to enable this in `user.env` if you run the mirror.

This greatly, greatly speeds up the image build process.
