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
    mov si, prompt
    call print_str

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

    mov si, cmd_v
    mov di, buffer
    mov cx, 11
    repe cmpsb
    je .cmd_version

    mov si, bad_msg
    call print_str
    jmp main_loop

.cmd_version:
    mov si, version_msg
    call print_str
    jmp main_loop

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

; ================= 数据区 =================
msg_loaded  db 'DeePoint Kernel Loaded!', 13, 10, 0
prompt      db 13, 10, 'DeePoint> ', 0
cmd_v       db 'deepoint -v'
bad_msg     db 13, 10, 'Bad command or file name', 0
version_msg db 13, 10, 'Copyright(C)2026 Creative Gear', 13, 10
            db 'All rights reserved', 13, 10
            db 'V0.0.1 (Floppy Unlocked!)', 13, 10, 0
buffer      times 64 db 0