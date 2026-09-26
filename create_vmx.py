#!/usr/bin/env python3
"""
Create a VMware .vmx configuration file for NOVA-OS.
"""

import sys
import os

def create_vmx(vmx_path, vmdk_path):
    vmx_content = f'''config.version = "8"
virtualHW.version = "19"
memsize = "32"
displayName = "NOVA-OS"
guestOS = "other"
numvcpus = "1"
scsi0.present = "TRUE"
scsi0.virtualDev = "lsilogic"
scsi0:0.present = "TRUE"
scsi0:0.fileName = "{os.path.basename(vmdk_path)}"
scsi0:0.deviceType = "disk"
ide0:0.present = "FALSE"
ethernet0.present = "FALSE"
usb.present = "FALSE"
sound.present = "FALSE"
mks.enable3d = "FALSE"
bios.bootDelay = "3000"
bios.forceSetupOnce = "TRUE"
'''
    
    with open(vmx_path, 'w') as f:
        f.write(vmx_content)
    
    print(f"[OK] Created VMX file: {vmx_path}")
    return True

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <output.vmx> <vmdk_path>")
        sys.exit(1)
    
    vmx_path = sys.argv[1]
    vmdk_path = sys.argv[2]
    
    create_vmx(vmx_path, vmdk_path)