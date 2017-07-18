##!/bin/bash

set -x
set -u
set -e

# See: https://github.com/archlinuxfr/yaourt/issues/67#issuecomment-68626199
function _yaourt() {(
	cp /usr/bin/makepkg /tmp/makepkg
	sed -i -e 's/if (( EUID == 0 )); then/if (( 1 == 2 )); then/g' /tmp/makepkg
	export MAKEPKG="/tmp/makepkg"
	yaourt "$@"
)}

## Arch Packages
CUSTOM_PACKAGES=()
CUSTOM_PACKAGES+=(zsh mosh openssh vim stow wget curl htop docker)
CUSTOM_PACKAGES+=(git subversion mercurial)
CUSTOM_PACKAGES+=(go python ruby perl rustup npm nodejs)
CUSTOM_PACKAGES+=(neovim python-neovim python2-neovim)
CUSTOM_PACKAGES+=(jq tig parallel jenkins weechat gist fzf python-pip rsync reflector)
CUSTOM_PACKAGES+=(kubectl-bin)
CUSTOM_PACKAGES+=(asciinema bind-tools weechat mitmproxy)

MANUAL_WALINUXAGENT=n

## Hostname
echo 'temporaryhostname' > /etc/hostname

## Timezone
#ln -s /usr/share/zoneinfo/UTC /etc/localtime

## Locale
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
export LANG=en_US.UTF-8
sed -i -e 's/\#en\_US/en\_US/g' /etc/locale.gen
locale-gen
echo 'KEYMAP=us' > /etc/vconsole.conf

# disable pkg compression
sed -i -e "s/PKGEXT='.pkg.tar.xz'/PKGEXT='.pkg.tar'/g" /etc/makepkg.conf

## Packages
pacman-db-upgrade
pacman -Syy --noconfirm
pacman -Syu --noconfirm

## Azure: HyperV Prep
sed -i 's/MODULES=""/MODULES="hv_balloon hv_utils hv_vmbus hv_storvsc hv_netvsc"/g' /etc/mkinitcpio.conf
mkinitcpio -p linux

## Bootloader
pacman --noconfirm -S grub
grub-install --target=i386-pc --recheck /dev/sda
sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT="quiet"|GRUB_CMDLINE_LINUX_DEFAULT="console=ttyS0 earlyprintk=ttyS0 rootdelay=300"|' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
cat /etc/default/grub

## Yaourt
packages=(package-query yaourt)
pacman -S base-devel yajl --needed --noconfirm
for pkg in "${packages[@]}"
do
	mkdir /tmp/$pkg
	chmod 0777 /tmp/$pkg
	(
		cd /tmp/$pkg
		curl "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=${pkg}" > PKGBUILD
		sudo -u nobody makepkg -s --noconfirm
		pacman -U ./$pkg*.pkg.tar --noconfirm
	)
	rm -rf /tmp/$pkg
done


## Install Custom Packages
_yaourt -S --noconfirm "${CUSTOM_PACKAGES[@]}"

## WALinuxAgent
if [[ MANUAL_WALINUXAGENT == 'y' ]]; then
	export WALINUX_VERSION=2.1.5
	# untested:
	# export WALINUX_VERSION=2.2.0

	pacman -S wget unzip parted python python-setuptools --noconfirm
	wget https://github.com/Azure/WALinuxAgent/archive/v${WALINUX_VERSION}.zip -O /tmp/walinuxagent.zip
	unzip /tmp/walinuxagent -d /opt/walinuxagent
	cd /opt/walinuxagent/WALinuxAgent-${WALINUX_VERSION}/
	python setup.py install --register-service

	cat <<-EOF >/etc/systemd/system/walinuxagent.service
	[Unit]
	Description=Azure Linux Agent
	After=network.target
	After=sshd.target

	[Service]
	Type=simple
	ExecStartPre=/bin/bash -c "cat /proc/net/route >> /dev/console || true"
	ExecStartPre=/bin/bash -c "journalctl -u dhcpcd@eth0 >> /dev/console || true"
	ExecStartPre=/bin/bash -c "ip addr >> /dev/console || true"
	ExecStart=/usr/bin/python3 /usr/sbin/waagent -daemon
	Restart=always

	[Install]
	WantedBy=multi-user.target
	EOF
else
	_yaourt -S --noconfirm walinuxagent
fi

# Required Services
systemctl enable sshd
# TODO: replace dhcpcd with something better
systemctl enable dhcpcd@eth0.service
#systemctl enable walinuxagent
systemctl enable waagent

## Cleanup
pacman -Scc --noconfirm
pacman -Sc --noconfirm
rm -f ~/.bash_history
rm -f /var/log/pacman.log
exec true
