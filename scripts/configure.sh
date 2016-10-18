#!/bin/bash

set -x
set -u
set -e

INSTALL_YAOURT="y"
WALINUXAGENT_INSTALL_MANUAL="y"

## Hostname
echo 'temporaryhostname' > /etc/hostname

## Timezone
ln -s /usr/share/zoneinfo/UTC /etc/localtime

## Locale
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
export LANG=en_US.UTF-8
sed -i -e 's/\\#en\\_US/en\\_US/g' /etc/locale.gen
locale-gen
echo 'KEYMAP=us' > /etc/vconsole.conf

## Packages
pacman-db-upgrade
pacman -Syy --noconfirm
pacman -Syu --noconfirm
pacman -S openssh --noconfirm

## Azure: HyperV Prep
sed -i 's/MODULES=""/MODULES="hv_balloon hv_utils hv_vmbus hv_storvsc hv_netvsc"/g' /etc/mkinitcpio.conf
mkinitcpio -p linux

## Bootloader
pacman --noconfirm -S grub
grub-install --target=i386-pc --recheck /dev/sda
sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT="quiet"|GRUB_CMDLINE_LINUX_DEFAULT="console=ttyS0 earlyprintk=ttyS0 rootdelay=300"|' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
cat /etc/default/grub

if [[ "${INSTALL_YAOURT}" == "y" ]]; then
  packages=(package-query yaourt)
  pacman -S base-devel yajl --needed --noconfirm

  cd /tmp;
  for pkg in "${packages[@]}"
  do
    mkdir $pkg
    chmod 0777 $pkg
    cd $pkg
    curl "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=${pkg}" > PKGBUILD
    sudo -u nobody makepkg -s --noconfirm
    pacman -U ./$pkg*.pkg.tar.xz --noconfirm

    cd ..
    rm -rf $pkg
  done
fi

pacman -S wget unzip parted python python-setuptools --noconfirm
export WALINUX_VERSION=2.1.5
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

systemctl enable sshd
systemctl enable dhcpcd@eth0.service
systemctl enable walinuxagent


## Cleanup
pacman -Scc --noconfirm
pacman -Sc --noconfirm
rm -f ~/.bash_history
rm -f /var/log/pacman.log
exec true
