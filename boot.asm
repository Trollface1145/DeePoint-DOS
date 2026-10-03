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

    ; 使用最原始、最硬核的 CHS 方式读取软盘
    ; 目标：把 LBA 1（C0, H0, S2）处的内核读到 0x7E00
    mov ax, 0x0000
    mov es, ax
    mov bx, 0x7E00      ; ES:BX = 0000:7E00

    mov ah, 0x02        ; BIOS 读扇区功能
    mov al, 4           ; 读取 4 个扇区（足够容纳你的 398 字节内核，还能留点余量）
    mov ch, 0           ; 柱面 0
    mov cl, 2           ; 扇区 2 (LBA 1)
    mov dh, 0           ; 磁头 0
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    ; 读取成功，跳转到内核！
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

; 强制填充到 510 字节，并加上 55 AA 签名
times 510 - ($ - $$) db 0
dw 0xAA55