# Bare Metal Zig

This project demonstrates how to create a basic "kernel" in Zig that runs on bare metal hardware.

## Overview

The goal is to create a freestanding Zig binary that can be run as a bootable kernel. The main steps are:

1. Compile a freestanding Zig binary
2. Make it multiboot compliant 
3. Add basic console output functionality
4. Create a bootable ISO image

## Requirements

- Zig 0.13.0
- QEMU
- GRUB2
- objconv
- xorriso (mkisofs)

For macOS, additional setup is required for GRUB2 and other dependencies. See the full article for details.

## Key Files

- `kernel.zig` - Main kernel code
- `console.zig` - Basic console output functionality  
- `grub.cfg` - GRUB bootloader configuration

## Building

1. Compile the kernel:
   ```
   zig build-exe kernel.zig -target x86-freestanding-none --script linker.ld
   ```

2. Create ISO directory structure:
   ```
   mkdir -p iso_dir/boot/grub/
   cp kernel iso_dir/boot/
   cp grub.cfg iso_dir/boot/grub/
   ```

3. Create bootable ISO:
   ```
   grub-mkrescue -o kernel.iso iso_dir
   ```

## Running

Run the kernel in QEMU:

```
qemu-system-x86_64 -cdrom kernel.iso -debugcon stdio -vga virtio -m 4G -machine "q35" -no-reboot -no-shutdown
```

![GRUB](https://github.com/user-attachments/assets/7d7c2199-54fe-431c-8304-98f8fcfbc9a4)

![OS](https://github.com/user-attachments/assets/ccf72ee9-1580-4e51-9e32-28c739bff411)


## Next Steps

- Add more kernel functionality

## Credits

This project is based on various online resources and guides, particularly Philipp Oppermann's "Writing an OS in Rust".
