#!/usr/bin/env bash

BASE_PKGS="base.list"
POST_PKGS="post.list"
PACMAN_CONF="pacman.conf"
DELAY="5s"

# Jump to the location of the script
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd )
cd "$SCRIPT_DIR"


main() {
    echo "----------------------------------"
    echo "PRE_REQUISITS"
    #check_iso
    keyboard_layout

    delay $DELAY
    check_efi

    delay $DELAY
    clear
    partitioning

    echo "----------------------------------"
    echo "INSTALL"

    delay $DELAY
    connect_wifi

    delay $DELAY
    change_mirrors $PACMAN_CONF "/etc/pacman.conf"
    
    delay $DELAY
    update_gpg_keys

    delay $DELAY
    install_base

    echo "----------------------------------"
    echo "POST_INSTALL"

    delay $DELAY
    generate_fstab

    delay $DELAY
    change_mirrors $PACMAN_CONF "/mnt/etc/pacman.conf"

    delay $DELAY
    change_root

    delay $DELAY
    post_install

    delay $DELAY
    add_user "strange"

    delay $DELAY
    timezone "America/Havana"

    delay $DELAY
    locale

    delay $DELAY
    grub

    delay $DELAY
    enable_network

    delay $DELAY
    enable_aur "strange"

    delay $DELAY
    finnish
}


delay() {
    sleep $1
}

check_iso() {
    echo -e "\e[95m**\e[0m  Check ISO Hash \e[95m**\e[0m"
    certutil -hashfile ./archlinux.iso SHA256
}

keyboard_layout() {
    echo -e "\e[95m**\e[0m Keyboard Layout to US \e[95m**\e[0m"
    loadkeys us
}

check_efi() {
    echo -e "\e[95m**\e[0m Check youre in EFI mode \e[95m**\e[0m"
    # if ls /sys/firmware/efi/efivars &> /dev/null; then
    if [[ -d "/sys/firmware/efi/efivars" ]]; then
        echo "😎 Correctly in EFI."
    else
        echo "😔 Youre not in EFI."
        echo "Reboot in EFI."
        echo "And re-run the script"
        return 1
    fi
}

partitioning() {
    echo "partitioning proccess"

    cfdisk
    lsblk

    echo "EFI partition (/dev/sda1): "
    read EFI_PARTITION

    echo "you want to format the EFI partition? (y/n)"
    read format_efi_answer

    echo "ROOT partition (/dev/sda2): "
    read ROOT_PARTITION

    if [[format_efi_answer == "y" || format_efi_answer == "Y"]]; then
        echo "formating $EFI_PARTITION as FAT32"
        mkfs.fat -F32 $EFI_PARTITION
    fi

    echo "formating $ROOT_PARTITION as BTRFS"
    mkfs.btrfs -L arch $ROOT_PARTITION

    echo "mounting $ROOT_PARTITION to /mnt"
    mount $ROOT_PARTITION /mnt

    echo "creating subvolumes"
    cd /mnt
    btrfs subvolume create @
    btrfs subvolume create @root
    btrfs subvolume create @home
    btrfs subvolume create @snapshots
    cd ..

    echo "unmounting $ROOT_PARTITION"
    umount /mnt

    echo "mounting $ROOT_PARTITION to /mnt"
    mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@root $ROOT_PARTITION /mnt

    echo "creating mount points"
    mkdir /mnt/{home,boot}
    mkdir /mnt/boot/efi
    mount $EFI_PARTITION /mnt/boot/efi

    echo "mounting home subvolume to /mnt/home"
    mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@home $ROOT_PARTITION /mnt/home
    
}

connect_wifi() {
    echo "Connect Wifi (y/n)"
    read answer

    if [[ "$answer" == "y"  || "$answer" == "Y" ]]; then
        echo -e "\e[95m**\e[0m Installing wifi-menu \e[95m**\e[0m"
        sudo pacman -S --needed  wifi-menu
        wifi-menu
    fi

}

change_mirrors() {
    echo -e "\e[95m**\e[0m Change Repo to uo.edu.cu \e[95m**\e[0m"
    
    mv "$2" "$2".backup
    cp "$1" "$2"

}

update_gpg_keys() {
    echo -e "\e[95m**\e[0m Updating GPG Keys \e[95m**\e[0m"

    pacman-key --init
    pacman-key --populate archlinux 
    pacman -Sy archlinux-keyring

}

install_base() {
    echo -e "\e[95m**\e[0m 🙏Installing Base Packages \e[95m**\e[0m"

    # archlinux-keyring -> contains all the gpg keys
    # pacstrap -> -i: prompts for package confirmation
    
    # grep -o '^[^#]*' base.list -> this will find lines that start without #
    # grep -o: tells grep to print only the parts that match with the pattern 
    # tr '\n' ' ' -> this replace endlines with ' '

    pacstrap /mnt $(grep -o '^[^#]*' "$BASE_PKGS" | tr '\n' ' ')

}

generate_fstab() {
    echo -e "\e[95m**\e[0m Generate fstab \e[95m**\e[0m"

    genfstab -U /mnt >> /mnt/etc/fstab

}

change_root() {
    echo -e "\e[95m**\e[0m Change Root \e[95m**\e[0m"

    arch-chroot /mnt

}

post_install() {
    echo -e "\e[95m**\e[0m Other Packages \e[95m**\e[0m"

    pacman -Sy $(grep -o '^[^#]*' "$POST_PKGS" | tr '\n' ' ')

}

add_user() {
    echo -e "\e[95m**\e[0m Creating User: $1 \e[95m**\e[0m"

    echo "1. creating user"
    sudo useradd -m "$1"
    
    echo "2. change password"
    sudo passwd "$1"

    echo "3. adding user to wheel group"
    sudo usermod -aG wheel "$1"

    #echo "Add user privileges"
    #Uncomment `%wheel ALL=(ALL:ALL) NOPASSWD: ALL` group.
}

timezone() {
    echo -e "\e[95m**\e[0m ☁️ Set Timezone \e[95m**\e[0m"

    # timedatectl set-local-rtc 1 -> for dual boot setups
    echo "1. set timezone to $1"
    ln -sf "/usr/share/zoneinfo/$1" /etc/localtime

    echo "2. sync hardware clock"
    hwclock --systohc

    echo "3. set local-rtc for compatibility with windows"
    timedatectl set-local-rtc 1

}

locale() {
    echo -e "\e[95m**\e[0m Locale Generation \e[95m**\e[0m"

    sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen
    locale-gen

}

grub() {
    echo -e "\e[95m**\e[0m Installing GRUB \e[95m**\e[0m"
    
    echo "1. Install grub pkg"
    pacman -S  --needed grub efibootmgr

    echo "2. Install grub in /boot/efi"
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
    
    echo "3. Creating grub.cfg"
    grub-mkconfig -o /boot/grub/grub.cfg

}

enable_network() {
    echo -e "\e[95m**\e[0m Enable NetworkManager \e[95m**\e[0m"

    systemctl enable NetworkManager
}

enable_aur() {
    echo -e "\e[95m**\e[0m Installing YAY \e[95m**\e[0m"

    cd /opt/

    echo "1. Downloading YAY from git"
    sudo git clone https://aur.archlinux.org/yay-git.git /opt
    cd yay-git
    
    echo "2. Changing Owner of /yay-git"
    sudo chown -R "$1:$1" yay-git

    echo "3. Compiling ..."
    sudo pacman -S --needed  go
    makepkg -si

    echo "4. Updating AUR"
    yay -Sy

}

finnish() {
    echo -e "\e[95m**\e[0m Exiting ... \e[95m**\e[0m"

    exit
    umount -a
    reboot
}


