# azure-archlinux-packer

**NOTE**: This is *not* supported by me (Cole Mickens), Microsoft, Azure, or ArchLinux. However, [Issues](https://github.com/colemickens/azure-archlinux-packer/issues) are welcome.

Builds, uploads, and deploys an [ArchLinux](https://www.archlinux.org/) image on Azure.

See below for [caveats](#caveats) and [TODOs](#TODO).


## Requirements

 * [Azure CLI](https://github.com/Azure/azure-cli) (the new Python Azure CLI) (`pip install --user azure-cli`)


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


### Build and Upload the Image

0. Choose some deployment values:
   ```shell
   export AZURE_SUBSCRIPTION_ID={some guid}
   export AZURE_CLIENT_ID={some guid}
   export AZURE_CLIENT_SECRET={some secret}
   export AZURE_RESOURCE_GROUP=colemick-acs-linuxdev
   export AZURE_STORAGE_ACCOUNT=colemickarchstrg
   export AZURE_STORAGE_CONTAINER=images
   export AZURE_VM_SIZE=Standard_F8S
   export AZURE_LOCATION=westus2
   ```

   If you are using [the local nginx mirror](#local-mirror), make sure to enable the pacman cache:
   ```shell
   export ENABLE_PACMAN_CACHE=y
   ```

1. Create a Storage Account.
   ```shell
   az storage account create \
       --resource-group="${RESOURCE_GROUP}" \
       --name="${STORAGE_ACCOUNT}" \
       --location="${LOCATION}" \
       --sku="Premium_LRS"
   ```

0. Prepare to build the image.
   ```shell
   cp ./example.env ./user.env

   # edit ./user.env
   vim ./user.env
   ```

1. Build and upload the image.
   ```shell
   ./build-in-docker.sh
   ```

The VHD URL will be in the `./_output` directory.


### Deploy a VM from the Image

This will try to determine the Arch Linux ISO URL from a previous upload.
You'll need to specify it manually if it wasn't uploaded recently or was deleted.

1. Deploy it!
   ```shell
   cd _deploy
   ./deploy.sh
   ```

2. That's it! Really!


## Caveats

1. This is not supported by me (Cole Mickens).

2. This is not supported by Microsoft or Azure.

3. This is not supported by ArchLinux.

4. The `walinuxagent` in this image isn't fully functional. This can lead
   to **real issues**, such as the VM failing to resize or extensions
   failing to provision.

   In fact, it may actual simply fail to provision properly...


## TODO

1. Remove `walinuxagent` whenever support for this is added to the Azure Platform.


## Advanced

### Local Mirror

The `local-mirror` directory includes a script that will run `nginx` as a reverse, caching proxy in front of some Arch Linux mirrors. Make sure to `export ENABLE_PACMAN_CACHE=y` to enable usage.

This greatly, greatly speeds up the image build process.
