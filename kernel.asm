bits 16
org 0x7E00
start:
    cli
    cld
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7000
    sti

    ; 1. 设置文本模式 + 美化光标
    mov ax, 0x0003
    int 0x10
    mov ah, 01h
    mov cx, 0x0607    ; 缩小下划线光标
    int 0x10

    ; 2. 打印带边框彩色开机LOGO
    mov si, logo_border
    mov bl, 0x0F       ; 亮白色文字
    call print_color

    ; 3. 打印欢迎标题（亮白）
    mov si, welcome_msg
    mov bl, 0x0F
    call print_color
    mov si, nl
    mov bl, 0x07
    call print_color

    ; 提示符循环
show_prompt_main:
    mov byte [len], 0
    mov si, prompt
    mov bl, 0x0A       ; 亮绿色提示符
    call print_color
read_key:
    xor ah, ah
    int 0x16
    cmp ah, 0x3F          ; F1 key
    je do_help
    cmp al, 3             ; Ctrl+C
    je do_exit
    cmp al, 13            ; Enter
    je enter
    cmp al, 8             ; Backspace
    je backspace
    cmp al, 32
    jb read_key
    cmp byte [len], 63
    jae read_key

    ; 写入输入缓冲区 + 回显默认灰色
    mov si, buf
    xor bx, bx
    mov bl, [len]
    add si, bx
    mov [si], al
    inc byte [len]
    mov ah, 0x0E
    int 0x10
    jmp read_key

do_help:
    mov si, nl
    mov bl, 0x07
    call print_color
    mov si, help_msg
    mov bl, 0x0B       ; 青色帮助文本
    call print_color
    jmp show_prompt_main

enter:
    push ax
    xor ax, ax
    mov es, ax
    pop ax
    mov si, nl
    mov bl, 0x07
    call print_color
    cld
    cmp byte [len], 0
    je show_prompt_main

    ; ========== 命令匹配逻辑 ==========
    cmp byte [len], 3
    jne chk_ver
    mov si, buf
    mov di, cmd_cls
    mov cx, 3
    repe cmpsb
    je do_cls
chk_ver:
    cmp byte [len], 3
    jne chk_dir
    mov si, buf
    mov di, cmd_ver
    mov cx, 3
    repe cmpsb
    je do_ver
chk_dir:
    cmp byte [len], 3
    jne chk_date
    mov si, buf
    mov di, cmd_dir
    mov cx, 3
    repe cmpsb
    je do_dir
chk_date:
    cmp byte [len], 4
    jne chk_time
    mov si, buf
    mov di, cmd_date
    mov cx, 4
    repe cmpsb
    je do_date
chk_time:
    cmp byte [len], 4
    jne chk_echo
    mov si, buf
    mov di, cmd_time
    mov cx, 4
    repe cmpsb
    je do_time
chk_echo:
    cmp byte [len], 4
    jne chk_whoami
    mov si, buf
    mov di, cmd_echo
    mov cx, 4
    repe cmpsb
    je do_echo
chk_whoami:
    cmp byte [len], 6
    jne chk_hack
    mov si, buf
    mov di, cmd_whoami
    mov cx, 6
    repe cmpsb
    je do_whoami
chk_hack:
    cmp byte [len], 6
    jne chk_hello
    mov si, buf
    mov di, cmd_hack
    mov cx, 6
    repe cmpsb
    je do_hack
chk_hello:
    cmp byte [len], 5
    jne chk_help
    mov si, buf
    mov di, cmd_hello
    mov cx, 5
    repe cmpsb
    je do_hello
chk_help:
    cmp byte [len], 4
    jne chk_exit
    mov si, buf
    mov di, cmd_help
    mov cx, 4
    repe cmpsb
    je do_help
chk_exit:
    cmp byte [len], 4
    jne chk_restart
    mov si, buf
    mov di, cmd_exit
    mov cx, 4
    repe cmpsb
    je do_exit
chk_restart:
    cmp byte [len], 7
    jne chk_python
    mov si, buf
    mov di, cmd_restart
    mov cx, 7
    repe cmpsb
    je do_restart
chk_python:
    mov si, buf
    mov di, cmd_python
    mov cx, 6
    cld
    repe cmpsb
    jne chk_unknown
    cmp byte [buf + 6], 0
    je do_python
    cmp byte [buf + 6], ' '
    je do_python
    cmp byte [buf + 6], 9
    je do_python
    jmp chk_unknown

chk_unknown:
    mov si, msg_unknown
    mov bl, 0x0C    ; 红色报错
    call print_color
    jmp show_prompt_main

; ========== 命令处理函数 ==========
do_cls:
    ; 完整清屏：清除全部80*25文本显存，修复清屏残留问题
    mov ax, 0x0600
    mov bh, 0x07    ; 黑底灰字填充空白
    xor cx, cx
    mov dx, 0x184F
    int 0x10
    ; 光标回到左上角
    mov ah, 02h
    xor bh, bh
    xor dx, dx
    int 0x10
    jmp show_prompt_main

do_ver:
    mov si, sys_version
    mov bl, 0x0B
    call print_color
    jmp show_prompt_main

do_dir:
    mov si, dir_header
    mov bl, 0x07
    call print_color
    mov si, dir_boot
    call print_color
    mov si, dir_kernel
    call print_color
    mov si, dir_files
    call print_color
    jmp show_prompt_main

do_date:
    mov si, msg_date
    mov bl, 0x0E
    call print_color
    mov ah, 0x04
    int 0x1A
    mov al, dh
    call print_hex
    mov al, '/'
    call print_char
    mov al, dl
    call print_hex
    mov al, '/'
    call print_char
    mov ax, cx
    call print_hex
    mov si, nl
    mov bl, 0x07
    call print_color
    jmp show_prompt_main

do_time:
    mov si, msg_time
    mov bl, 0x0E
    call print_color
    mov ah, 0x02
    int 0x1A
    mov al, ch
    call print_hex
    mov al, ':'
    call print_char
    mov al, cl
    call print_hex
    mov al, ':'
    call print_char
    mov al, dh
    call print_hex
    mov si, nl
    mov bl, 0x07
    call print_color
    jmp show_prompt_main

do_echo:
    mov si, nl
    mov bl, 0x07
    call print_color
    mov si, buf + 5
    mov cx, [len]
    sub cx, 5
    jz show_prompt_main
.echo_loop:
    lodsb
    mov ah, 0x0E
    int 0x10
    loop .echo_loop
    mov si, nl
    mov bl, 0x07
    call print_color
    jmp show_prompt_main

do_whoami:
    mov si, msg_whoami
    mov bl, 0x0D
    call print_color
    jmp show_prompt_main

do_hack:
    mov byte [hack], 1
    call rain
    jmp show_prompt_main

do_hello:
    mov si, msg_hello
    mov bl, 0x0A
    call print_color
    jmp show_prompt_main

do_python:
    mov si, buf
    add si, 6
.skip_space:
    cmp byte [si], ' '
    je .advance
    cmp byte [si], 9
    je .advance
    jmp .parse
.advance:
    inc si
    jmp .skip_space
.parse:
    cmp byte [si], 0
    je .show_help
    mov di, py_help
    mov cx, 4
    repe cmpsb
    je .show_help
    mov di, py_print
    mov cx, 5
    repe cmpsb
    je .print_string
    mov si, msg_python_unsupported
    mov bl, 0x0C
    call print_color
    mov si, nl
    mov bl, 0x07
    call print_color
    jmp show_prompt_main
.show_help:
    mov si, msg_python_help
    mov bl, 0x0E
    call print_color
    mov si, nl
    mov bl, 0x07
    call print_color
    jmp show_prompt_main
.print_string:
    cmp byte [si], '('
    jne .unsupported
    inc si
    cmp byte [si], '"'
    jne .unsupported
    inc si
    mov bx, si
    mov di, si
.scan_loop:
    cmp byte [di], '"'
    je .string_done
    cmp byte [di], 0
    je .unsupported
    inc di
    jmp .scan_loop
.string_done:
    mov byte [di], 0
    mov si, bx
    mov bl, 0x0A
    call print_color
    mov si, nl
    mov bl, 0x07
    call print_color
    jmp show_prompt_main
.unsupported:
    mov si, msg_python_unsupported
    mov bl, 0x0C
    call print_color
    mov si, nl
    mov bl, 0x07
    call print_color
    jmp show_prompt_main

; ========== 修复后的关机EXIT命令 ==========
do_exit:
    call cls
    mov si, msg_shutdown
    mov bl, 0x0F
    call print_color
    mov si, nl
    mov bl, 0x07
    call print_color

    ; 1. APM 16位关机（虚拟机/老主板优先）
    mov ax, 0x5300
    xor bx, bx
    int 0x15
    jc .try_acpi
    mov ax, 0x5301
    xor bx, bx
    int 0x15
    jc .try_acpi
    mov ax, 0x5308
    mov bx, 0x0001
    mov cx, 0x0001
    int 0x15
    mov ax, 0x5307
    mov bx, 0x0001
    mov cx, 0x0003
    int 0x15

.try_acpi:
    ; 2. ACPI S5 关机端口（现代真机）
    mov dx, 0xB004
    mov ax, 0x2000
    out dx, ax
    mov dx, 0x604
    mov ax, 0x2000
    out dx, ax
    mov dx, 0xB006
    mov ax, 0x2000
    out dx, ax
    mov dx, 0xB004
    mov ax, 0x4000
    out dx, ax
    mov dx, 0x604
    mov ax, 0x4000
    out dx, ax

    ; 3. QEMU 专用退出端口（虚拟机必触发）
    mov dx, 0x501
    xor ax, ax
    out dx, al

    ; 4. 硬件不支持关机时提示并停机
    mov si, msg_shutdown_fail
    mov bl, 0x0C
    call print_color
    mov si, nl
    mov bl, 0x07
    call print_color
.halt_loop:
    cli
    hlt
    jmp .halt_loop

do_restart:
    call cls
    mov si, msg_restart
    mov bl, 0x0F
    call print_color
    mov si, nl
    mov bl, 0x07
    call print_color

    ; APM软重启
    mov ax, 0x5301
    xor bx, bx
    int 0x15
    jc .kb_reset
    mov ax, 0x5307
    mov bx, 0x0001
    mov cx, 0x0000
    int 0x15
.kb_reset:
    ; 键盘控制器硬重启
    mov al, 0xFE
    out 0x64, al
    ; 兜底三重故障
.reboot_halt:
    cli
    hlt
    jmp .reboot_halt

backspace:
    cmp byte [len], 0
    je read_key
    dec byte [len]
    mov ah, 0x0E
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10
    jmp read_key

; ========== 彩色打印函数 ==========
; 输入: si=字符串指针, bl=前景色(0~15)
print_color:
    push ax
    push bx
    push si
.print_loop:
    cld
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    mov bh, 0       ; 页面0
    mov bl, bl      ; 前景色
    int 0x10
    jmp .print_loop
.done:
    pop si
    pop bx
    pop ax
    ret

; 普通单色打印（兼容原有逻辑）
print:
    mov bl, 0x07
    call print_color
    ret

print_char:
    push ax
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x07
    int 0x10
    pop ax
    ret

print_hex:
    push ax
    push bx
    mov bl, al
    shr al, 4
    call .hex_digit
    mov al, bl
    and al, 0x0F
    call .hex_digit
    pop bx
    pop ax
    ret
.hex_digit:
    cmp al, 9
    jbe .num
    add al, 7
.num:
    add al, '0'
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x07
    int 0x10
    ret

cls:
    mov ax, 0x0600
    mov bh, 0x07
    xor cx, cx
    mov dx, 0x184F
    int 0x10
    mov ah, 2
    xor bh, bh
    xor dx, dx
    int 0x10
    ret

delay:
    push cx
    push dx
    mov cx, 0xFFFF
.delay_loop:
    mov dx, 0xFFFF
.inner_loop:
    dec dx
    jnz .inner_loop
    loop .delay_loop
    pop dx
    pop cx
    ret

rain:
    push ax
    push bx
    push cx
    push dx
    push si
    push ds
    push es
    mov ax, 0xB800
    mov es, ax
    xor si, si
.rloop:
    cmp byte [hack], 0
    je .done
    mov ah, 6
    mov al, 1
    mov bh, 0x0A
    mov cx, 0x0100
    mov dx, 0x184F
    int 0x10
    mov di, 3840
    mov cx, 80
.col:
    mov al, [rain_col]
    cbw
    add ax, si
    and al, 0x5F
    add al, 32
    mov ah, 0x0A
    stosw
    inc byte [rain_col]
    loop .col
    inc si
    call check_kb
    jnc .rloop
.done:
    mov byte [hack], 0
    call cls
    pop es
    pop ds
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

check_kb:
    mov ah, 1
    int 0x16
    jz .no
    xor ah, ah
    int 0x16
.clear_buf:
    mov ah, 1
    int 0x16
    jz .done_clear
    xor ah, ah
    int 0x16
    jmp .clear_buf
.done_clear:
    stc
    ret
.no:
    clc
    ret

; ==================== 字符串常量 ====================
logo_border db '',13,10,0
welcome_msg db 'Welcome to Nova OS', 0
prompt db 'C:\> ', 0
nl db 13, 10, 0

cmd_cls db 'cls'
cmd_ver db 'ver'
cmd_dir db 'dir'
cmd_date db 'date'
cmd_time db 'time'
cmd_echo db 'echo'
cmd_whoami db 'whoami'
cmd_hack db 'Hacker'
cmd_hello db 'Hello'
cmd_help db 'help'
cmd_exit db 'exit'
cmd_restart db 'restart'
cmd_python db 'python'
py_help db 'help'
py_print db 'print'

help_msg db 13, 10
         db 'Available commands:', 13, 10
         db '  cls      - Clear screen', 13, 10
         db '  ver      - Show version', 13, 10
         db '  dir      - List files', 13, 10
         db '  date     - Show date', 13, 10
         db '  time     - Show time', 13, 10
         db '  echo     - Print text', 13, 10
         db '  whoami   - Show user', 13, 10
         db '  Hacker   - Matrix rain', 13, 10
         db '  Hello    - Greeting', 13, 10
         db '  exit     - Shutdown', 13, 10
         db '  restart  - Restart system', 13, 10
         db '  python   - Python-like mini command', 13, 10
         db '  F1       - This help', 13, 10, 0

msg_unknown db 'Bad command or file name', 13, 10, 0
msg_date db 'Current date: ', 0
msg_time db 'Current time: ', 0
msg_whoami db 'nova\administrator', 13, 10, 0
msg_hello db 'Hello, welcome to NOVA-OS!', 13, 10, 0
msg_python_help db 'Python mini-shell enabled. Supported: python / python print("text")', 13, 10, 0
msg_python_unsupported db 'Python subset not supported: use python print("text") or just python', 13, 10, 0
msg_shutdown db 'NOVA-OS 正在关机...', 0
msg_shutdown_fail db 'BIOS/ACPI does not support power-off on this machine; halting CPU.', 13, 10, 0
msg_restart db 'NOVA-OS 正在重启...', 0

dir_header db 13, 10, ' Volume in drive C has no label.', 13, 10
             db ' Directory of C:\', 13, 13, 10, 0
dir_boot db ' BOOT     IMG       512  08-26-26  12:00a', 13, 10, 0
dir_kernel db ' KERNEL   BIN       505  08-26-26  12:00a', 13, 10, 0
dir_files db '        2 file(s)          1,017 bytes', 13, 10
            db '        0 dir(s)    104,856,583 bytes free', 13, 10, 0

sys_version db 13,10,'  _   _      _ _         __  __           _      ',13,10
            db ' | \ | | ___| | | ___   |  \/  | __ _ _ __ (_)_  __',13,10
            db ' |  \| |/ _ \ | |/ _ \  | |\/| |/ _` | `_ \| \ \/ /',13,10
            db ' | |\  |  __/ | | (_) | | |  | | (_| | | | | |>  < ',13,10
            db ' |_| \_|\___|_|_|\___/  |_|  |_|\__,_|_| |_|_/_/\_\',13,10
            db '                                                     ',13,10
            db ' Version 1.0.0 | Build 2026.08.26',13,10
            db ' (C) 2026 NOVA Systems. All rights reserved.',13,10,0

; 全局变量
len db 0
hack db 0
rain_col db 0
buf times 64 db 0
null_idt dw 0, 0, 0
