#!/bin/bash

echo -ne "
--------------------------------------------------------
                _     _            _____          _____ 
  __ _ _ __ ___| |__ / |_ ____   _|___ / _ __ ___|___ / 
 / _  |  __/ __|  _ \| |  _ \ \ / / |_ \|  __/ __| |_ \ 
| (_| | | | (__| | | | | | | \ V / ___) | |  \__ \___) |
 \__,_|_|  \___|_| |_|_|_| |_|\_/ |____/|_|  |___/____/ 
--------------------------------------------------------
            Automated Arch Linux Installer
--------------------------------------------------------
        Scripts are in directory named Arch1nv3rs3


--------------------------------------------------------
            Initiating Pre-Installation...
--------------------------------------------------------
"
loadkeys pt-latin1
iso=$(curl -4 ifconfig.co/country-iso)
timedatectl set-ntp true
pacman -S --noconfirm archlinux-keyring # Update keyrings to latest to prevent packages failing to install
pacman -S --noconfirm --needed pacman-contrib terminus-font
setfont ter-v22b
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
pacman -S --noconfirm --needed reflector rsync grub
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
mkdir /mnt &>/dev/null # Hiding error message if any

pacman -S --noconfirm --needed gptfdisk btrfs-progs glibc # Installing prerequisites

echo -ne "
--------------------------------------------------------
                  Formating the Disk...
--------------------------------------------------------
"
umount -A --recursive /mnt # Unmount everything before we start
lsblk
echo -n "Please select the disk you want to use: [ex: /dev/sda]: "
DISK=$(read -r)
echo $DISK
sgdisk -Z ${DISK} # Zap all on disk
sgdisk -a 2048 -o ${DISK} # New gpt disk 2048 alignment

# Creating partitions
sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK} # partition 1 (BIOS Boot Partition)
sgdisk -n 2::+300M --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DISK} # partition 2 (UEFI Boot Partition)
sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK} # partition 3 (Root), default start, remaining
if [[ ! -d "/sys/firmware/efi" ]]; then # Checking for bios system
    sgdisk -A 1:set:2 ${DISK}
fi
partprobe ${DISK} # reread partition table to ensure it is correct

# make filesystems