# azure-archlinux-packer

Builds, uploads, and deploys an [ArchLinux](https://www.archlinux.org/) image on Azure.


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
   export AZURE_LOCATION=westus2
   ```

   If you are using the local nginx mirror, make sure to enable the pacman cache:
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

The VHD URL will be in the `./build/_output` directory.


### Deploy a VM from the Image

This will try to determine the Arch Linux ISO URL from a previous upload.
You'll need to specify it manually if it wasn't uploaded recently or was deleted.

1. Deploy it!
   ```shell
   cd _deploy
   ./deploy.sh
   ```

2. That's it! Really!


## Advanced

### Local Mirror

The `local-mirror` directory includes a script that will run `nginx` as a reverse, caching proxy in front of some Arch Linux mirrors. Make sure to `export ENABLE_PACMAN_CACHE=y` to enable usage.
