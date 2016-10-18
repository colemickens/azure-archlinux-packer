## azure-archlinux-packer

Builds and uplods an Arch Linux image for running on Azure.

Usage:

1. Build and upload the image.
   ```shell

   ```
   The VHD URL will be in the `./build/_output` directory.

2. Deploy it using [this quickstart template]().


## Advanced

You can `export DEV=y` before running `./build-in-docker.sh`
to drop into bash and have your current checkout mounted into the container
for development and faster iteration.

The `local-mirror` directory includes a script that will run `nginx` as a reverse, caching proxy in front of some Arch Linux mirrors. Make sure to `export ENABLE_PACMAN_CACHE=y` to enable usage.
