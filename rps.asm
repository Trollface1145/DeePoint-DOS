BITS 16
ORG 0x3000

rps_start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    cld

    mov si, msg_rps_intro
    call print_str

.rps_loop:
    ; 生成电脑选择 (0=黑脸, 1=白脸, 2=心)
    mov ah, 0x00
    int 0x1A
    mov ax, dx
    xor dx, dx
    mov bx, 3
    div bx
    mov [comp_choice], dl

    mov si, msg_rps_prompt
    call print_str

.wait_key:
    mov ah, 0x00
    int 0x16
    test al, al
    jz .wait_key

    ; 【Ctrl+C 中断检测】
    cmp al, 0x03
    je .quit_game

    cmp al, 'q'
    je .quit_game
    cmp al, 'Q'
    je .quit_game
    cmp al, '1'
    je .player_rock
    cmp al, '2'
    je .player_scissors
    cmp al, '3'
    je .player_paper
    jmp .wait_key

.player_rock:
    mov al, '1'      ; 【修复】使用字符 '1'，不要用数字 1
    jmp .got_input
.player_scissors:
    mov al, '2'      ; 【修复】使用字符 '2'
    jmp .got_input
.player_paper:
    mov al, '3'      ; 【修复】使用字符 '3'
.got_input:
    mov ah, 0x0E
    int 0x10         ; 正常回显 '1', '2', '3'
    sub al, '0'      ; '1' (0x31) 变成 1 (0x01)
    dec al           ; 1 变成 0 (黑脸)
    mov [player_choice], al

    ; 打印电脑选择
    mov si, msg_rps_comp_chose
    call print_str
    mov dl, [comp_choice]
    cmp dl, 0
    je .show_rock
    cmp dl, 1
    je .show_scissors
    mov si, msg_paper
    jmp .print_comp_choice
.show_rock:
    mov si, msg_rock
    jmp .print_comp_choice
.show_scissors:
    mov si, msg_scissors
.print_comp_choice:
    call print_str

    ; 判定胜负
    mov dl, [comp_choice]
    mov al, [player_choice]
    
    cmp al, dl
    je .tie
    
    cmp al, 0       ; 玩家黑脸（石头）
    jne .check_scissors
    cmp dl, 1       ; 电脑白脸（剪刀）
    je .win
    jmp .lose

.check_scissors:
    cmp al, 1       ; 玩家白脸（剪刀）
    jne .check_paper
    cmp dl, 2       ; 电脑心（布）
    je .win
    jmp .lose

.check_paper:
    cmp al, 2       ; 玩家心（布）
    jne .lose
    cmp dl, 0       ; 电脑黑脸（石头）
    je .win
    jmp .lose

.tie:
    mov si, msg_tie
    call print_str
    jmp .rps_loop
.win:
    mov si, msg_win
    call print_str
    jmp .rps_loop
.lose:
    mov si, msg_lose
    call print_str
    jmp .rps_loop

.quit_game:
    mov si, msg_ctrl_c
    call print_str
    jmp 0x0000:0x7E00

; --- 打印函数 ---
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
comp_choice   db 0
player_choice db 0
msg_rps_intro db 13, 10, '=== Black Face, White Face, Heart ===', 13, 10
              db '1=Black Face, 2=White Face, 3=Heart', 13, 10
              db 'Q=Quit (or Ctrl+C)', 13, 10, 0
msg_rps_prompt db 13, 10, 'Your choice: ', 0
msg_rps_comp_chose db 13, 10, 'Computer chose: ', 0
; 直接用 ASCII 控制字符打印图形
msg_rock     db 'Black Face (', 2, ')', 0     ; 0x02 是 ☻
msg_scissors db 'White Face (', 1, ')', 0     ; 0x01 是 ☺
msg_paper    db 'Heart (', 3, ')', 0          ; 0x03 是 ♥
msg_win      db 13, 10, 'You win!', 13, 10, 0
msg_lose     db 13, 10, 'You lose!', 13, 10, 0
msg_tie      db 13, 10, 'Tie!', 13, 10, 0
msg_ctrl_c   db '^C', 13, 10, 0