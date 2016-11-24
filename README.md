# azure-archlinux-packer

## Overview

**Functionality**:

1. Creates an Arch Linux image capable of running on Azure
2. Uploads the image to an Azure Storage Account, creating it if necessary
3. Deploys a VM with an instance of the uploaded image

**Disclaimers**:

1. This is not supported by me (Cole Mickens) though [Issues](https://github.com/colemickens/azure-archlinux-packer/issues) are welcome.
2. This is not supported by Microsoft or Azure.
3. This is not supported by Arch Linux.
4. Please go read the [details](#details) section again to understand what you're
   getting into.


## Requirements

 * `docker` (optional, but expected by `make`)
 * `make`
 * An Azure AD ServicePrincipal with access to the target subscription


## Details

This process creates an Arch Linux image with:

  * a 30GB image
  * `yaourt` along with many of my favorite packages pre-installed

The list of pre-installed packages can be modified by editing
`scripts/configure.sh`.

This process creates the following assets in Azure:

  * a Premium Storage Account
  * a VirtualNetwork and Subnet
  * a Network Security Group (with rules for SSH, Mosh, HTTP, HTTPS and ports 9000-9999)
  * a VM (defaults to `Standard_F8S`) from an instance of the created Arch Linux image
  * a **1TB** Premium data disk attached to the VM
  * a public IP attached to the VM


### Build and Upload and Deploy the Image

0. Prepare by copying `user.env.template` to `user.env` and filling in the values as appropriate:
   ```shell
   cp ./user.env.template ./user.env
   vim user.env
   ```

2. Build, upload and deploy the image:
   ```shell
   make
   ```
Alternatively, you can call the commands manually with `make {build,upload,deploy}`,
or you can run the actual shell scripts by hand. This avoids needing `docker` but
in return requirements a number of other dependencies.


## TODO

1. Remove `walinuxagent` whenever Azure supports agent-less Linux. (It might already...)


## Advanced

### Local Mirror

The `local-mirror` directory includes a script that will run `nginx` as a reverse, caching proxy in front of some Arch Linux mirrors.
Make sure to enable this in `user.env` if you run the mirror.

This greatly, greatly speeds up the image build process.
