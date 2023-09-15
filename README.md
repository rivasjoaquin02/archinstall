
# Installation of Arch Linux

[Official ArchLinux Guide](https://wiki.archlinux.org/title/installation_guide)


## Script 
```shell
git clone https://github.com/rivasjoaquin02/archinstall

cd archinstall  
chmod +x install.sh
sudo ./install.sh
```

## Manual Installation

Check Hash
```shell
certutil -hashfile ./archlinux.iso SHA256	
```

1. Change keyboard layout
```sh
loadkeys us
```

2. Verify boot mode
```sh
ls /sys/firmware/efi/efivars  # If directory exists, EFI is supported.
```

3. Partitioning

|  |  | |
|-|-|-|
| /dev/sda1 | efi | fat |
| /dev/sda2 | root | btrfs  |


```sh
mkfs.fat -F32 /dev/sda1
mkfs.btrf -L arch /dev/sda2

mount /dev/sda2 /mnt
btrfs subvolume create @
btrfs subvolume create @root
btrfs subvolume create @home
btrfs subvolume create @snapshots

umount /mnt
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@root /dev/sda2 /mnt

mkdir /mnt/{home,boot}
mkdir /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi

mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@home /dev/sda2 /mnt/home
```


4. Connect WIFI
```bash
sudo pacman -S wifi-menu
wifi-menu
```

5. Update GPG keys
```bash
pacman-key --init
pacman-key --populate archlinux
```

Before install change mirrors to UO
```bash
Server = http://download.jovenclub.cu/repos/archlinux/$repo/os/$arch
```

6. Install
```sh
pacman -Sy archlinux-keyring
pacstrap -i /mnt base linux-lts linux-lts-headers linux-firmware intel-ucode 
```

7. Generate file system table
```sh
genfstab -U -p /mnt >> /mnt/etc/fstab
```

8. `chroot` into system
```sh
arch-chroot /mnt
pacman -S networkmanager vim git
```

9. add user
```sh
useradd -m strange
usermod -aG wheel strange

passwd
passwd strange
```

10. add user privileges
Uncomment `%wheel ALL=(ALL:ALL) NOPASSWD: ALL` group.
```sh
export EDITOR=vim; visudo
```

11. Set timezone
```sh
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc
```

> Using DualBoot with Windows? Set `timedatectl set-local-rtc 1`. Explanation can be found [here](https://itsfoss.com/wrong-time-dual-boot/).

12. Set locale
```sh
sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen
locale-gen
```

13. Create EFI boot directory
```sh
mkdir /boot/EFI
mount /dev/sda1 /boot/EFI
```

14. Install grub
```sh
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
```

15. Finish install
Enable `NetworkManager` and reboot.

```sh
systemctl enable NetworkManager

exit
umount -a
reboot
```


## post-install

Connect wifi
```
nmcli device wifi connect <SSID> password <password>
```


```sh
sudo pacman -S tlp
```
 
* `tlp`: energy saving
* `btrfs-progs`: manage BTRFS filesystem

install yay
```bash
cd /opt/

sudo git clone https://aur.archlinux.org/yay-git.git
cd yay-git
sudo chown -R <user>:<user> yay-git

sudo pacman -S go #this is for avoid install got from the AUR
makepkg -si

yay -Syu
```