bits 16
org 0x7C00

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    
    mov [boot_drive], dl
    
    mov ax, 0x0003
    int 0x10

    mov si, msg_loading
    call print

    ; Check if booting from CD-ROM (DL >= 0xE0)
    cmp dl, 0xE0
    jae .cdrom_boot
    
    ; HDD/USB boot: load kernel from disk
    mov si, dap
    mov ah, 0x42
    int 0x13
    jc disk_error
    jmp .done_load

.cdrom_boot:
    ; CD-ROM no-emulation: kernel already at 0x7C00+512=0x7E00
    ; No disk read needed!

.done_load:
    mov si, msg_ok
    call print

    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7000      ; Stack below boot sector (avoid overwriting kernel at 0x7E00)
    sti
    jmp 0x0000:0x7E00

disk_error:
    mov si, msg_err
    call print
.halt:
    hlt
    jmp .halt

print:
    cld
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print
.done:
    ret

boot_drive db 0
msg_loading db 'Loading NOVA-OS...', 13, 10, 0
msg_ok db 'OK', 13, 10, 13, 10, 0
msg_err db 'Disk error!', 13, 10, 0

; Disk Address Packet for LBA read
dap:
    db 0x10           ; Packet size
    db 0              ; Reserved
    dw 16             ; Sectors to read (8KB)
    dw 0x7E00         ; Buffer offset
    dw 0x0000         ; Buffer segment
    dq 1              ; LBA start sector (sector 1 = after boot sector)

; Pad to boot signature
times 510-($-$$) db 0
dw 0xAA55