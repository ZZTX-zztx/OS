#!/usr/bin/env python3
"""
Create a VMware-compatible disk image with proper MBR partition table.
Optimized for large disk images using sparse file creation.
"""

import struct
import sys
import os

def create_disk_image(boot_img_path, kernel_bin_path, output_path):
    SECTOR_SIZE = 512
    TOTAL_SECTORS = 204800  # 100MB disk (204800 * 512 = 100MB)
    DISK_SIZE = TOTAL_SECTORS * SECTOR_SIZE
    
    with open(boot_img_path, 'rb') as f:
        boot_data = f.read()
    
    with open(kernel_bin_path, 'rb') as f:
        kernel_data = f.read()
    
    if len(boot_data) != 512:
        print(f"[ERROR] Boot image must be exactly 512 bytes, got {len(boot_data)}")
        return False
    
    if boot_data[510:512] != b'\x55\xaa':
        print("[ERROR] Invalid boot signature")
        return False
    
    # Create partition table
    partition_entry = struct.pack('<BBBBBBBBII',
        0x80,           # Boot indicator: active
        0x00,           # CHS start head
        0x01,           # CHS start sector
        0x00,           # CHS start cylinder
        0x0B,           # Partition type: FAT32 LBA
        0x00,           # CHS end head
        0x00,           # CHS end sector
        0x00,           # CHS end cylinder
        1,              # LBA start (sector 1)
        TOTAL_SECTORS - 1  # Sector count
    )
    
    # Build first sector with MBR
    first_sector = bytearray(512)
    first_sector[0:512] = boot_data
    first_sector[0x1BE:0x1BE + 16] = partition_entry
    first_sector[510] = 0x55
    first_sector[511] = 0xAA
    
    # Write disk image efficiently
    with open(output_path, 'wb') as f:
        # Write first sector (boot + MBR)
        f.write(bytes(first_sector))
        
        # Write kernel data starting at sector 1
        f.write(kernel_data)
        
        # Seek to end to create sparse file (much faster than writing zeros)
        f.seek(DISK_SIZE - 1)
        f.write(b'\x00')
    
    print(f"[OK] Created disk image: {output_path}")
    print(f"     Size: {DISK_SIZE} bytes ({DISK_SIZE / 1024 / 1024:.1f} MB)")
    print(f"     Sectors: {TOTAL_SECTORS}")
    return True

if __name__ == '__main__':
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} <boot.img> <kernel.bin> <output.img>")
        sys.exit(1)
    
    boot_img = sys.argv[1]
    kernel_bin = sys.argv[2]
    output = sys.argv[3]
    
    if not os.path.exists(boot_img):
        print(f"[ERROR] Boot image not found: {boot_img}")
        sys.exit(1)
    
    if not os.path.exists(kernel_bin):
        print(f"[ERROR] Kernel not found: {kernel_bin}")
        sys.exit(1)
    
    create_disk_image(boot_img, kernel_bin, output)