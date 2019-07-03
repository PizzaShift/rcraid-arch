#!/bin/sh
original_dir=$(pwd)
DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

echo -e "\nCompiling and installing kernel module...\n"

mount -o remount,size=2G /run/archiso/cowspace &> /dev/null
pacman -S binutils sudo
useradd rcraid -m &> /dev/null

grep -qF -- "rcraid ALL=(ALL) NOPASSWD:ALL" /etc/sudoers &> /dev/null || echo "rcraid ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
mkdir /tmp/rcraid &> /dev/null
cp $DIR/PKGBUILD /tmp/rcraid/
cp $DIR/dkms.conf /tmp/rcraid/
cp $DIR/linux-4.15.patch /tmp/rcraid/
cp $DIR/raid_linux_driver_8_01_00_039_public.zip /tmp/rcraid/
chown rcraid:rcraid /tmp/rcraid -R
su - rcraid -c "cd /tmp/rcraid ; makepkg -si || exit"
rm -rf /tmp/rcraid
sed -i '/rcraid ALL=(ALL) NOPASSWD:ALL/d' /etc/sudoers
userdel rcraid
cd $original_dir

echo -e "\nUnloading AHCI modules..."
rmmod ahci libahci -s

echo -e "\nEnabling rcraid module..."
modprobe rcraid -s

echo -e "\n"
read -r -p "Configure grub? [Y/n]" response
response=${response,,}
if [[ $response =~ ^(yes|y| ) ]] || [[ -z $response ]]; then
    mount -a
    echo -e "\nConfiguring grub..."
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& modprobe.blacklist=ahci/' /etc/default/grub
    grub-mkconfig -o /boot/grub/grub.cfg
    mkinitcpio -p linux
fi

echo -e "\nAll done, run this script with chroot to apply changes on system."
