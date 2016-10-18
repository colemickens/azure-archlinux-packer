# azure-archlinux-packer

Builds and uplods an Arch Linux image for running on Azure.

## Usage

### Build and Upload the Image

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

#### Method 1: Template Deployment Online

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcolemickens%2Fazure-archlinux-packer%2Fmaster%2F_deploy%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

#### Method 2: Template Deployment From Script

0. Choose a resource group name
   ```shell
   export RESOURCE_GROUP=colemick-resource-group
   ```

1. Create the resource group
   ```shell
   az resource group create --name='colemick-resource-group' --location='westus2'
   ```

2. Deploy template into the resource group
   ```shell
   cd _deploy
   ./deploy.sh
   ```

## Advanced

You can `export DEV=y` before running `./build-in-docker.sh`
to drop into bash and have your current checkout mounted into the container
for development and faster iteration.

The `local-mirror` directory includes a script that will run `nginx` as a reverse, caching proxy in front of some Arch Linux mirrors. Make sure to `export ENABLE_PACMAN_CACHE=y` to enable usage.
