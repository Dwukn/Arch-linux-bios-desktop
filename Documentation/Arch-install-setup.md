# Arch Setup

---

## ✅ Step 1: Boot into Arch ISO (UEFI Mode)

---

### Confirm UEFI Boot:

```
❯ efibootmgr
```

If it returns entries, you're in UEFI mode.

---

## ✅ Step 2: Setup Reflector & Mirrors

```
❯ pacman -Sy reflector
❯ cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup # Creating this will let you have a backup of your mirrors in case something goes wrong with reflector
❯ reflector --country {yourCountry} --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
```
* replace {yourCountry} with your contry of residence
---

## ✅ Step 3: Pacman Optimization

Edit `/etc/pacman.conf`:

```
ParallelDownloads = 11
Color
ILoveCandy
```

---

## ✅ Step 4: Disk Partitioning (Example: /dev/nvme0n1)

### GPT Partition Table:

- EFI: 1024M (FAT32, type EF00)
- Root: Rest of disk (type 8300)

---

## ✅ Step 5: Format & Mount

```
mkfs.fat -F32 /dev/nvme0n1p1
mkfs.btrfs /dev/nvme0n1p2

mount /dev/nvme0n1p2 /mnt

btrfs su cr /mnt/@
btrfs su cr /mnt/@home
btrfs su cr /mnt/@log
btrfs su cr /mnt/@pkg
btrfs su cr /mnt/@.snapshots

umount /mnt

# Mount with subvols
mount -o noatime,compress=zstd,space_cache=v2,subvol=@ /dev/nvme0n1p2 /mnt
mkdir -p /mnt/{boot,home,var/log,var/cache/pacman/pkg,.snapshots}

mount -o compress=zstd,subvol=@home /dev/nvme0n1p2 /mnt/home
mount -o compress=zstd,subvol=@log /dev/nvme0n1p2 /mnt/var/log
mount -o compress=zstd,subvol=@pkg /dev/nvme0n1p2 /mnt/var/cache/pacman/pkg
mount -o compress=zstd,subvol=@.snapshots /dev/nvme0n1p2 /mnt/.snapshots
mount /dev/nvme0n1p1 /mnt/boot
```

---

## ✅ Step 6: Base Installation

```
pacstrap -K /mnt base linux-lts linux-firmware intel-ucode btrfs-progs zram-generator
```

---

## ✅ Step 7: Fstab & Chroot

```
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
```

---

## ✅ Step 8: System Config

```
echo archbox > /etc/hostname
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc

# Locale
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Pacman tweaks again
nano /etc/pacman.conf  # ensure ParallelDownloads = 11 etc
```

---

## ✅ Step 9: Bootloader (GRUB + EFI)

```
pacman -S grub efibootmgr os-prober
mkdir -p /boot/EFI

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

# Enable Btrfs snapshots for GRUB
pacman -S grub-btrfs

grub-mkconfig -o /boot/grub/grub.cfg
```

---

## ✅ Step 10: User, Network, ZRAM

```
passwd
useradd -mG wheel dawood
passwd dawood

# Enable sudo
pacman -S sudo
EDITOR=vim visudo
## Uncomment: %wheel ALL=(ALL:ALL) ALL

# Enable network
pacman -S NetworkManager
systemctl enable NetworkManager

# zram config
nano /etc/systemd/zram-generator.conf
```

Example config:

```
[zram0]
zram-size = ram / 2
type = zstd
```

---

## ✅ Step 11: Wayland Setup (Hyprland + Pipewire + SDDM)

```
pacman -S hyprland sddm sddm-kcm xdg-desktop-portal-hyprland waybar kitty
pacman -S pipewire wireplumber

systemctl enable sddm
```

---

## ✅ Step 12: Timeshift Setup

```
pacman -S timeshift timeshift-autosnap
pacman -S snap-pac
```

Check that Timeshift integrates with Btrfs and GRUB.

---

## ✅ Optional: AUR Helper

```
pacman -S git base-devel
cd /opt
git clone https://aur.archlinux.org/paru.git
chown -R dawood:wheel paru
cd paru
makepkg -si
```

---

## ✅ Done!
