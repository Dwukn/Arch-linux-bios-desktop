# BIOS Configuration Guide for Linux Systems

This document outlines recommended BIOS settings for running modern Linux distributions such as Arch, Fedora, and Ubuntu. These settings prioritize compatibility, performance, and virtualization features while disabling legacy or restrictive options like Secure Boot.

---

## ✅ Essential BIOS Settings

These settings are **required or highly recommended** to ensure a stable and bootable Linux environment.

| **Setting**               | **Value**   | **Notes**                                                                 |
|---------------------------|-------------|---------------------------------------------------------------------------|
| **CSM Support**           | Disabled    | Enables pure UEFI boot mode. Required for modern distros like Arch.       |
| **Secure Boot**           | Disabled    | Necessary to boot unsigned Linux kernels or unsigned GRUB configs.        |
| **Fast Boot**             | Disabled    | Allows proper hardware initialization and easier diagnostics.             |
| **Boot Option Priority**  | Set to main Linux disk | Ensures system boots to the correct OS/disk.                          |
| **Bootup Unlock State**   | On          | Enables automatic unlock for convenience (e.g. auto-login with disk unlock). |
| **Full Screen Logo Show** | Enabled     | Cosmetic setting. Optional.                                               |
| **Security Option**       | System      | Not critical unless multi-user secure boot is needed.                     |

---

## 🔧 Advanced BIOS Settings (Recommended)

These settings improve system performance, virtualization support, and GPU/device compatibility.

| **Setting**                 | **Recommended Value** | **Location / Notes**                                                                 |
|-----------------------------|------------------------|--------------------------------------------------------------------------------------|
| **SVM (Secure Virtual Machine)** | Enabled               | Located under `M.I.T > Advanced CPU Settings` or similar. Required for virtualization (KVM/QEMU). |
| **IOMMU**                   | Enabled                | Located under `Chipset`. Required for device passthrough, GPU isolation, and VFIO. |
| **Memory XMP / DOCP Profile** | Enabled              | Under `M.I.T > Memory Settings`. Enables full RAM speed (e.g., 3200MHz for G.Skill). |
| **PCIe Slot Configuration** | Auto / Gen3 / Gen4     | Under `Chipset`. Choose according to GPU capabilities. Most modern GPUs support Gen4. |
| **Above 4G Decoding**       | Enabled                | Needed for large GPUs or PCIe passthrough (VFIO).                                   |
| **Resizable BAR**           | Enabled (Optional)     | May improve GPU performance in some applications and games.                          |
| **NVMe RAID**               | Disabled               | Disable unless you're explicitly setting up RAID. Simplifies Linux installations.   |

---

## 💡 Notes

- **CSM (Compatibility Support Module)** must be off for native UEFI boot. This allows for cleaner boot setups and avoids hybrid/legacy issues.
- **Secure Boot** may interfere with unsigned bootloaders and custom kernel modules. Disabling it allows full control over your Linux system.
- If you plan to use virtualization (e.g., for KVM, Docker, Proxmox), enabling **SVM** and **IOMMU** is essential.
- Always double-check **Boot Priority** after changing settings, especially when switching from Windows to Linux.

---

## 🛠 Useful Tips

- After saving BIOS settings, use a tool like `efibootmgr` in Linux to confirm the EFI boot order.
- For GPU passthrough, verify IOMMU groups using:

```bash
  find /sys/kernel/iommu_groups/ -type l
```

* For XMP profiles, ensure your motherboard supports your memory kit’s rated speed. Misconfigurations can cause boot loops.



## ✅ Final Checks Before Install
* [ ] UEFI Boot Mode confirmed?
* [ ] Secure Boot is off?
* [ ] XMP Profile applied?
* [ ] SVM and IOMMU enabled?
* [ ] Boot disk priority set correctly?

If all checks pass, you're ready to install or run your Linux system!
