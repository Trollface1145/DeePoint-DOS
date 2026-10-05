BITS 16
ORG 0x7C00

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov [boot_drive], dl

    ; 读取 18 个扇区（约 9KB）的内核到 0x7E00
    mov ax, 0x0000
    mov es, ax
    mov bx, 0x7E00

    mov ah, 0x02
    mov al, 18          ; 读取 18 个扇区（一个磁道）
    mov ch, 0           ; 柱面 0
    mov cl, 2           ; 扇区 2（LBA 1）
    mov dh, 0           ; 磁头 0
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    jmp 0x0000:0x7E00

disk_error:
    mov si, err_msg
.print:
    lodsb
    test al, al
    jz .halt
    mov ah, 0x0E
    int 0x10
    jmp .print
.halt:
    cli
    hlt
    jmp .halt

boot_drive db 0
err_msg db 'KLE!', 0

times 510 - ($ - $$) db 0
dw 0xAA55