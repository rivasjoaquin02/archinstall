
# Installation of Arch Linux

https://wiki.archlinux.org/title/installation_guide

## Installation

> [!Note] Check Hash
> 
>```powershell
>certutil -hashfile ./archlinux.iso SHA256	
>```
> 

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
iwctl
station wlan0 show
station wlan0 scan
station wlan0 connect for <SSID> psk
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

## HyperLand (WM)
(with github.com/soldoestech/hyprv3.git)

```bash
git clone https://github.com/soldoestech/hyprv3.git
cd hyprv3
sudo chmod +x set-hypr
```


| Package                       | Description                                                                                                  |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------ |
| linux-headers                 | Headers and scripts for building modules for the Linux kernel                                                |
| nvidia-dkms                   | NVIDIA drivers - module sources                                                                              |
| qt5-wayland                   | Provides APIs for Wayland                                                                                    |
| qt5ct                         | Qt5 Configuration Utility                                                                                    |
| libva                         | Video Acceleration (VA) API for Linux                                                                        |
| libva-nvidia-driver-git [AUR] | VA-API implementation that uses NVDEC as a backend (git version)                                             |
| ---                           | ---                                                                                                          |
| hyprland                      | a highly customizable dynamic tiling Wayland compositor                                                      |
| kitty                         | A modern, hackable, featureful, OpenGL-based terminal emulator                                               |
| jq                            | Command-line JSON processor                                                                                  |
| mako                          | Lightweight notification daemon for Wayland                                                                  |
| wofi                          | launcher for wlroots-based wayland compositors                                                               |
| xdg-desktop-portal-hyprland   | xdg-desktop-portal backend for hyprland                                                                      |
| swappy                        | A Wayland native snapshot editing tool                                                                       |
| grim                          | Screenshot utility for Wayland                                                                               |
| slurp                         | Select a region in a Wayland compositor                                                                      |
| thunar                        | Modern, fast and easy-to-use file manager for Xfce                                                           |
| polkit-gnome                  | Legacy polkit authentication agent for GNOME                                                                 |
| python-requests               | Python HTTP for Humans                                                                                       |
| pamixer                       | Pulseaudio command-line mixer like amixer                                                                    |
| pavucontrol                   | PulseAudio Volume Control                                                                                    |
| brightnessctl                 | Lightweight brightness control tool                                                                          |
| bluez                         | Daemons for the bluetooth protocol stack                                                                     |
| bluez-utils                   | Development and debugging utilities for the bluetooth protocol stack                                         |
| blueman                       | GTK+ Bluetooth Manager                                                                                       |
| network-manager-applet        | Applet for managing network connection                                                                       |
| gvfs                          | Virtual filesystem implementation for GIO                                                                    |
| thunar-archive-plugin         | Adds archive operations to the Thunar file context menus                                                     |
| file-roller                   | Create and modify archives                                                                                   |
| btop                          | A monitor of system resources, bpytop ported to C++                                                          |
| pacman-contrib                | Contributed scripts and tools for pacman systems                                                             |
| starship                      | The cross-shell prompt for astronauts                                                                        |
| ttf-jetbrains-mono-nerd       | Patched font JetBrains Mono from nerd fonts library                                                          |
| noto-fonts-emoji              | Google Noto emoji fonts                                                                                      |
| lxappearance                  | Feature-rich GTK+ theme switcher of the LXDE Desktop                                                         |
| xfce4-settings                | Xfce's Configuration System                                                                                  |
| sddm-git [AUR]                | The Simple Desktop Display Manager                                                                           |
| sddm-sugar-candy-git [AUR]    | Sugar Candy is the sweetest login theme available for the SDDM display manager                               |
| waybar-hyprland [AUR]         | Highly customizable Wayland bar for Sway and Wlroots based compositors, with workspaces support for Hyprland |
| swww [AUR]                    | Efficient animated wallpaper daemon for wayland, controlled at runtime.                                      |
| swaylock-effects [AUR]        | A fancier screen locker for Wayland.                                                                         |
| wlogout [AUR]                 | Logout menu for wayland                                                                                      |

* [sddm-git](https://builds.garudalinux.org/repos/chaotic-aur/x86_64/#sddm-git)
* sddm-sugar-candy-git
* [waybar-hyprland](https://builds.garudalinux.org/repos/chaotic-aur/x86_64/#waybar-hyprland)
* [swaylock-effects](https://builds.garudalinux.org/repos/chaotic-aur/x86_64/#swaylock-effects)
* [wlogout](https://builds.garudalinux.org/repos/chaotic-aur/x86_64/#wlogout)
* swww