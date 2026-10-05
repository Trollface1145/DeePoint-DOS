BITS 16
ORG 0x3000

guess_start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    cld

    ; 生成 1-100 随机数
    mov ah, 0x00
    int 0x1A
    mov al, dl
    xor ah, ah
    mov bl, 100
    div bl
    inc ah
    mov [target_num], ah

    mov si, msg_guess_intro
    call print_str

.guess_loop:
    mov si, msg_guess_prompt
    call print_str

    xor bx, bx
.read_digit:
    mov ah, 0x00
    int 0x16
    test al, al
    jz .read_digit
    
    ; 【Ctrl+C 中断检测】
    cmp al, 0x03
    je .quit_game

    cmp al, 0x0D
    je .check_guess
    cmp al, '0'
    jb .read_digit
    cmp al, '9'
    ja .read_digit

    mov ah, 0x0E
    int 0x10
    sub al, '0'
    push ax
    mov ax, bx
    mov cx, 10
    mul cx
    mov bx, ax
    pop ax
    xor ah, ah
    add bx, ax
    jmp .read_digit

.check_guess:
    mov al, 0x0D
    call print_char
    mov al, 0x0A
    call print_char

    xor ax, ax
    mov al, [target_num]
    cmp bx, ax
    je .guess_win
    ja .guess_high
    jb .guess_low

.guess_high:
    mov si, msg_guess_high
    call print_str
    jmp .guess_loop

.guess_low:
    mov si, msg_guess_low
    call print_str
    jmp .guess_loop

.guess_win:
    mov si, msg_guess_win
    call print_str
    jmp 0x0000:0x7E00

.quit_game:
    mov si, msg_ctrl_c
    call print_str
    jmp 0x0000:0x7E00

; --- 函数区 ---
print_char:
    push ax
    push bx
    mov ah, 0x0E
    mov bx, 0x0007
    int 0x10
    pop bx
    pop ax
    ret

print_str:
    push ax
    push si
.loop:
    lodsb
    test al, al
    jz .done
    call print_char
    jmp .loop
.done:
    pop si
    pop ax
    ret

; --- 数据区 ---
target_num  db 0
msg_guess_intro   db 13, 10, '=== DeePoint Guess Game ===', 13, 10
                  db 'I am thinking of a number between 1 and 100.', 13, 10, 0
msg_guess_prompt  db 13, 10, 'Your guess (Ctrl+C to quit): ', 0
msg_guess_high    db 'Too high! Try again.', 13, 10, 0
msg_guess_low     db 'Too low! Try again.', 13, 10, 0
msg_guess_win     db 13, 10, 'Congratulations! You got it!', 13, 10, 0
msg_ctrl_c        db '^C', 13, 10, 0