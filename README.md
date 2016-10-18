# azure-archlinux-packer

Builds and uplods an Arch Linux image for running on Azure.

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
   export RESOURCE_GROUP=colemick-acs-linuxdev
   export STORAGE_ACCOUNT=colemickarchstrg
   export LOCATION=westus2
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

You can `export DEV=y` before running `./build-in-docker.sh`
to drop into bash and have your current checkout mounted into the container
for development and faster iteration.

The `local-mirror` directory includes a script that will run `nginx` as a reverse, caching proxy in front of some Arch Linux mirrors. Make sure to `export ENABLE_PACMAN_CACHE=y` to enable usage.
