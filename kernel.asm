BITS 16
ORG 0x7E00

jmp kernel_start        ; 跳过数据区

; ================= 数据区 =================
msg_loaded  db 'DeePoint Kernel Loaded!', 13, 10, 0
prompt      db 13, 10, 'DeePoint> ', 0

echo_flag   db 1
cmd_clear   db 'clear'
cmd_help    db 'help'
cmd_guess   db 'guess'
cmd_rps     db 'rps'
cmd_date    db 'date'
cmd_time    db 'time'
cmd_beep    db 'beep'
cmd_echo    db 'echo '
cmd_echo_off db 'echo off'
cmd_echo_on  db 'echo on'
cmd_shutdown db 'shutdown'
cmd_reboot   db 'reboot'
cmd_v       db 'deepoint -v'

bad_msg     db 13, 10, 'Bad command or file name', 0
newline_msg db 13, 10, 0
msg_beep    db 13, 10, '*BEEP!*', 13, 10, 0
msg_date_prefix db 13, 10, 'Date: ', 0
msg_time_prefix db 13, 10, 'Time: ', 0
msg_load_error db 13, 10, 'Module load error!', 0
msg_ctrl_c  db '^C', 13, 10, 0

version_msg db 13, 10, 'Copyright(C)2026 Creative Gear', 13, 10
            db 'All rights reserved', 13, 10
            db 'V0.0.7 (Ctrl+C & Modular Games)', 13, 10, 0

help_msg    db 13, 10, 'Available commands:', 13, 10
            db '  help          - Show this help', 13, 10
            db '  clear         - Clear the screen', 13, 10
            db '  guess         - Play guessing game', 13, 10
            db '  rps           - Play rock paper scissors', 13, 10
            db '  date          - Show current date', 13, 10
            db '  time          - Show current time', 13, 10
            db '  beep          - Emit a PC speaker beep', 13, 10
            db '  echo [text]   - Print text with newline', 13, 10
            db '  echo -n [text]- Print text without newline', 13, 10
            db '  echo off/on   - Hide/Show prompt', 13, 10
            db '  shutdown      - Power off the system', 13, 10
            db '  reboot        - Restart the system', 13, 10
            db '  deepoint -v   - Show version info', 13, 10, 0

msg_echo_off db 13, 10, 'Echo is off.', 13, 10, 0
msg_echo_on  db 13, 10, 'Echo is on.', 13, 10, 0
msg_shutdown db 13, 10, 'Shutting down...', 13, 10, 0
msg_reboot   db 13, 10, 'Rebooting...', 13, 10, 0

boot_drive  db 0
buffer      times 64 db 0

; ================= 函数区 =================
print_char:
    push ax
    push bx
    push cx
    push dx
    mov ah, 0x0E
    mov bx, 0x0007
    int 0x10
    pop dx
    pop cx
    pop bx
    pop ax
    ret

print_str:
    push ax
    push si
.print_str_loop:
    lodsb
    test al, al
    jz .print_str_done
    call print_char
    jmp .print_str_loop
.print_str_done:
    pop si
    pop ax
    ret

print_bcd:
    push ax
    shr al, 4
    add al, '0'
    call print_char
    pop ax
    and al, 0x0F
    add al, '0'
    call print_char
    ret

; ================= 主循环 =================
kernel_start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    cld

    mov si, msg_loaded
    call print_str

main_loop:
    cmp byte [echo_flag], 0
    je .skip_prompt
    mov si, prompt
    call print_str
.skip_prompt:

    mov di, buffer
    mov cx, 64
    xor al, al
    rep stosb
    mov di, buffer

.wait_key:
    mov ah, 0x00
    int 0x16
    test al, al
    jz .wait_key
    
    ; 【Ctrl+C 中断检测】
    cmp al, 0x03
    je .ctrl_c
    
    cmp al, 0x0D
    je .process_cmd
    cmp al, 0x08
    je .backspace

    mov cx, di
    sub cx, buffer
    cmp cx, 62
    jae .wait_key

    stosb
    mov ah, 0x0E
    push di
    int 0x10
    pop di
    jmp .wait_key

.ctrl_c:
    mov si, msg_ctrl_c
    call print_str
    jmp main_loop

.backspace:
    cmp di, buffer
    je .wait_key
    dec di
    mov byte [di], 0
    mov al, 0x08
    mov ah, 0x0E
    push di
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    pop di
    jmp .wait_key

.process_cmd:
    mov al, 0x0D
    call print_char
    mov al, 0x0A
    call print_char

    cmp byte [buffer], 0
    je main_loop

    ; ============== 命令分发 ==============
    mov si, cmd_shutdown
    mov di, buffer
    mov cx, 8
    repe cmpsb
    je cmd_shutdown_handler

    mov si, cmd_reboot
    mov di, buffer
    mov cx, 6
    repe cmpsb
    je cmd_reboot_handler

    mov si, cmd_echo_off
    mov di, buffer
    mov cx, 8
    repe cmpsb
    je cmd_echo_off_handler

    mov si, cmd_echo_on
    mov di, buffer
    mov cx, 7
    repe cmpsb
    je cmd_echo_on_handler

    mov si, cmd_clear
    mov di, buffer
    mov cx, 5
    repe cmpsb
    je cmd_clear_handler

    mov si, cmd_help
    mov di, buffer
    mov cx, 4
    repe cmpsb
    je cmd_help_handler

    mov si, cmd_guess
    mov di, buffer
    mov cx, 5
    repe cmpsb
    je cmd_guess_handler

    mov si, cmd_rps
    mov di, buffer
    mov cx, 3
    repe cmpsb
    je cmd_rps_handler

    mov si, cmd_date
    mov di, buffer
    mov cx, 4
    repe cmpsb
    je cmd_date_handler

    mov si, cmd_time
    mov di, buffer
    mov cx, 4
    repe cmpsb
    je cmd_time_handler

    mov si, cmd_beep
    mov di, buffer
    mov cx, 4
    repe cmpsb
    je cmd_beep_handler

    mov si, cmd_echo
    mov di, buffer
    mov cx, 5
    repe cmpsb
    je cmd_echo_handler

    mov si, cmd_v
    mov di, buffer
    mov cx, 11
    repe cmpsb
    je cmd_version_handler

    mov si, bad_msg
    call print_str
    jmp main_loop

; ============== 命令实现 ==============
cmd_guess_handler:
    ; 加载 LBA 20 (柱面0, 磁头1, 扇区3) 的 guess.bin 到 0x3000
    push ds
    push es
    mov ax, 0x0000
    mov es, ax
    mov bx, 0x3000
    mov ah, 0x02
    mov al, 4
    mov ch, 0
    mov cl, 3
    mov dh, 1
    mov dl, [boot_drive]
    int 0x13
    pop es
    pop ds
    jc .guess_load_error
    jmp 0x0000:0x3000
.guess_load_error:
    mov si, msg_load_error
    call print_str
    jmp main_loop

cmd_rps_handler:
    ; 加载 LBA 24 (柱面0, 磁头1, 扇区7) 的 rps.bin 到 0x3000
    push ds
    push es
    mov ax, 0x0000
    mov es, ax
    mov bx, 0x3000
    mov ah, 0x02
    mov al, 4
    mov ch, 0
    mov cl, 7
    mov dh, 1
    mov dl, [boot_drive]
    int 0x13
    pop es
    pop ds
    jc .rps_load_error
    jmp 0x0000:0x3000
.rps_load_error:
    mov si, msg_load_error
    call print_str
    jmp main_loop

cmd_clear_handler:
    mov ah, 0x06
    mov al, 0x00
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
    mov ah, 0x02
    mov bh, 0x00
    mov dx, 0x0000
    int 0x10
    jmp main_loop

cmd_help_handler:
    mov si, help_msg
    call print_str
    jmp main_loop

cmd_date_handler:
    mov ah, 0x04
    int 0x1A
    mov si, msg_date_prefix
    call print_str
    mov al, ch
    call print_bcd
    mov al, cl
    call print_bcd
    mov al, '-'
    call print_char
    mov al, dh
    call print_bcd
    mov al, '-'
    call print_char
    mov al, dl
    call print_bcd
    mov si, newline_msg
    call print_str
    jmp main_loop

cmd_time_handler:
    mov ah, 0x02
    int 0x1A
    mov si, msg_time_prefix
    call print_str
    mov al, ch
    call print_bcd
    mov al, ':'
    call print_char
    mov al, cl
    call print_bcd
    mov al, ':'
    call print_char
    mov al, dh
    call print_bcd
    mov si, newline_msg
    call print_str
    jmp main_loop

cmd_beep_handler:
    mov al, 0xB6
    out 0x43, al
    mov ax, 0x0533
    out 0x42, al
    mov al, ah
    out 0x42, al
    in al, 0x61
    or al, 0x03
    out 0x61, al
    mov cx, 0x004C
    mov dx, 0x4B40
    mov ah, 0x86
    int 0x15
    in al, 0x61
    and al, 0xFC
    out 0x61, al
    mov si, msg_beep
    call print_str
    jmp main_loop

cmd_echo_handler:
    cmp byte [di], '-'
    jne .echo_regular
    cmp byte [di+1], 'n'
    jne .echo_regular
    add di, 2
    cmp byte [di], ' '
    jne .echo_no_space
    inc di
.echo_no_space:
    mov si, di
    call print_str
    jmp main_loop
.echo_regular:
    mov si, di
    call print_str
    mov si, newline_msg
    call print_str
    jmp main_loop

cmd_version_handler:
    mov si, version_msg
    call print_str
    jmp main_loop

cmd_echo_off_handler:
    mov byte [echo_flag], 0
    mov si, msg_echo_off
    call print_str
    jmp main_loop

cmd_echo_on_handler:
    mov byte [echo_flag], 1
    mov si, msg_echo_on
    call print_str
    jmp main_loop

cmd_shutdown_handler:
    mov si, msg_shutdown
    call print_str
    mov dx, 0x604
    mov ax, 0x2000
    out dx, ax
    cli
    hlt
    jmp cmd_shutdown_handler

cmd_reboot_handler:
    mov si, msg_reboot
    call print_str
    mov dx, 0xCF9
    mov al, 0x06
    out dx, al
    cli
    hlt
    jmp cmd_reboot_handler