BITS 16
ORG 0x7E00

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
    ; 1. shutdown (长度 8)
    mov si, cmd_shutdown
    mov di, buffer
    mov cx, 8
    repe cmpsb
    je .cmd_shutdown

    ; 2. reboot (长度 6)
    mov si, cmd_reboot
    mov di, buffer
    mov cx, 6
    repe cmpsb
    je .cmd_reboot

    ; 3. echo off (长度 8)
    mov si, cmd_echo_off
    mov di, buffer
    mov cx, 8
    repe cmpsb
    je .cmd_echo_off

    ; 4. echo on (长度 7)
    mov si, cmd_echo_on
    mov di, buffer
    mov cx, 7
    repe cmpsb
    je .cmd_echo_on

    ; 5. clear (长度 5)
    mov si, cmd_clear
    mov di, buffer
    mov cx, 5
    repe cmpsb
    je .cmd_clear

    ; 6. help (长度 4)
    mov si, cmd_help
    mov di, buffer
    mov cx, 4
    repe cmpsb
    je .cmd_help

    ; 7. echo (前缀，长度 5，带空格)
    mov si, cmd_echo
    mov di, buffer
    mov cx, 5
    repe cmpsb
    je .cmd_echo

    ; 8. deepoint -v (长度 11)
    mov si, cmd_v
    mov di, buffer
    mov cx, 11
    repe cmpsb
    je .cmd_version

    mov si, bad_msg
    call print_str
    jmp main_loop

; ============== 命令实现 ==============
.cmd_clear:
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

.cmd_help:
    mov si, help_msg
    call print_str
    jmp main_loop

.cmd_echo:
    ; DI 指向 "echo " 之后的位置
    ; 检查 -n 前缀参数
    cmp byte [di], '-'
    jne .echo_regular
    cmp byte [di+1], 'n'
    jne .echo_regular
    add di, 2
    ; 跳过可能存在的空格
    cmp byte [di], ' '
    jne .echo_no_space
    inc di
.echo_no_space:
    ; 不换行打印
    mov si, di
    call print_str
    jmp main_loop
.echo_regular:
    mov si, di
    call print_str
    mov si, newline_msg
    call print_str
    jmp main_loop

.cmd_version:
    mov si, version_msg
    call print_str
    jmp main_loop

.cmd_echo_off:
    mov byte [echo_flag], 0
    mov si, msg_echo_off
    call print_str
    jmp main_loop

.cmd_echo_on:
    mov byte [echo_flag], 1
    mov si, msg_echo_on
    call print_str
    jmp main_loop

.cmd_shutdown:
    mov si, msg_shutdown
    call print_str
    mov dx, 0x604
    mov ax, 0x2000
    out dx, ax
    cli
    hlt
    jmp .cmd_shutdown

.cmd_reboot:
    mov si, msg_reboot
    call print_str
    ; 使用 PCI 复位控制寄存器 (0xCF9)
    mov al, 0x06      ; 0x02 = 系统复位, 0x04 = 完整复位
    out 0xCF9, al
    ; 如果失败，则停机
    cli
    hlt
    jmp .cmd_reboot

; ============== 函数区 ==============
print_str:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    mov bx, 0x0007
    int 0x10
    jmp print_str
.done:
    ret

print_char:
    mov ah, 0x0E
    mov bx, 0x0007
    int 0x10
    ret

; ============== 数据区 ==============
msg_loaded  db 'DeePoint Kernel Loaded!', 13, 10, 0
prompt      db 13, 10, 'DeePoint> ', 0

echo_flag   db 1
cmd_clear   db 'clear'
cmd_help    db 'help'
cmd_echo    db 'echo '
cmd_echo_off db 'echo off'
cmd_echo_on  db 'echo on'
cmd_shutdown db 'shutdown'
cmd_reboot   db 'reboot'
cmd_v       db 'deepoint -v'

bad_msg     db 13, 10, 'Bad command or file name', 0
newline_msg db 13, 10, 0

version_msg db 13, 10, 'Copyright(C)2026 Creative Gear', 13, 10
            db 'All rights reserved', 13, 10
            db 'V0.0.3 (- Prefix Unlocked!)', 13, 10, 0

help_msg    db 13, 10, 'Available commands:', 13, 10
            db '  help          - Show this help', 13, 10
            db '  clear         - Clear the screen', 13, 10
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

buffer      times 64 db 0