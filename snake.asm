BITS 16
ORG 0x3000

jmp snake_start

; ================= 数据区 =================
direction   db 2
snake_len   db 3
snake_x     times 100 db 0
snake_y     times 100 db 0
food_x      db 0
food_y      db 0
score_val   db 0
old_tail_x  db 0
old_tail_y  db 0
new_head_x  db 0
new_head_y  db 0
msg_game_over db 13, 10, 'GAME OVER! You crashed!', 13, 10, 0
msg_score     db 13, 10, 'Your score: ', 0

; ================= 延迟 =================
; int 15h AH=86h   CX:DX = 微秒数
; 0x00030D40 = 200000 us = 200ms
; 想更慢：改成 0x0007A120 (500ms) 或 0x000F4240 (1s)
; 想更快：改成 0x000186A0 (100ms)
delay_ticks:
    push ax
    push cx
    push dx
    mov cx, 0x0003
    mov dx, 0x0D40
    mov ah, 0x86
    int 0x15
    pop dx
    pop cx
    pop ax
    ret

; ================= 清屏（直接写显存） =================
clear_screen:
    push ax
    push cx
    push di
    push es
    mov ax, 0xB800
    mov es, ax
    xor di, di
    mov ax, 0x0720          ; 空格 + 黑底白字
    mov cx, 2000
    rep stosw
    pop es
    pop di
    pop cx
    pop ax
    ret

; ================= 画格子 =================
; AL=字符  BL=属性  CH=X  CL=Y
draw_cell:
    push ax
    push bx
    push cx
    push dx
    push di
    push es
    push ax
    xor ax, ax
    mov al, cl
    mov dx, 80
    mul dx
    xor dx, dx
    mov dl, ch
    add ax, dx
    shl ax, 1
    mov di, ax
    pop ax
    mov dx, 0xB800
    mov es, dx
    mov [es:di], al
    inc di
    mov [es:di], bl
    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ================= 画整条蛇 =================
draw_snake:
    push ax
    push bx
    push cx
    push di
    push si
    xor ax, ax
    mov al, [snake_len]
    mov si, ax
    xor di, di
.loop:
    cmp di, si
    jge .done
    mov al, '#'
    mov bl, 0x02
    test di, di
    jnz .not_head
    mov al, '@'
    mov bl, 0x0A
.not_head:
    mov ch, [snake_x + di]
    mov cl, [snake_y + di]
    push si
    push di
    call draw_cell
    pop di
    pop si
    inc di
    jmp .loop
.done:
    pop si
    pop di
    pop cx
    pop bx
    pop ax
    ret

; ================= 生成食物坐标（不画） =================
spawn_food:
.retry:
    mov ah, 0x00
    int 0x1A
    add dx, [score_val]
    mov ax, dx
    xor dx, dx
    mov bx, 76
    div bx
    add dl, 2
    mov [food_x], dl

    mov ah, 0x00
    int 0x1A
    add dx, [score_val]
    mov ax, dx
    xor dx, dx
    mov bx, 21
    div bx
    add dl, 2
    mov [food_y], dl

    xor cx, cx
    mov cl, [snake_len]
    xor di, di
.check:
    cmp di, cx
    jge .ok
    mov al, [food_x]
    cmp al, [snake_x + di]
    jne .next
    mov al, [food_y]
    cmp al, [snake_y + di]
    je .retry
.next:
    inc di
    jmp .check
.ok:
    ret

; ================= 画食物 =================
draw_food:
    mov al, 'O'
    mov bl, 0x0C
    mov ch, [food_x]
    mov cl, [food_y]
    call draw_cell
    ret

; ================= 数字 =================
print_num:
    push ax
    push bx
    push dx
    xor ah, ah
    mov bl, 10
    div bl
    add al, '0'
    call print_char
    mov al, ah
    add al, '0'
    call print_char
    pop dx
    pop bx
    pop ax
    ret

; ================= 字符/字符串 =================
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

; ================= 游戏结束音 =================
beep_game_over:
    mov al, 0xB6
    out 0x43, al
    mov ax, 0x0A00
    out 0x42, al
    mov al, ah
    out 0x42, al
    in al, 0x61
    or al, 0x03
    out 0x61, al
    mov cx, 0xFFFF
.d:
    loop .d
    in al, 0x61
    and al, 0xFC
    out 0x61, al
    ret

; ================= 主程序 =================
snake_start:
    cli
    mov ax, 0x3000          ; 【核心修复】硬编码 DS=0x3000
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x2000
    sti
    cld

    call clear_screen

    ; 初始化蛇
    mov byte [direction], 2
    mov byte [snake_len], 3
    mov byte [snake_x], 40
    mov byte [snake_y], 12
    mov byte [snake_x + 1], 39
    mov byte [snake_y + 1], 12
    mov byte [snake_x + 2], 38
    mov byte [snake_y + 2], 12
    mov byte [score_val], 0

    call spawn_food

.game_loop:
    ; 键盘
    mov ah, 0x01
    int 0x16
    jz .no_key
    mov ah, 0x00
    int 0x16
    cmp al, 'q'
    je .quit_game
    cmp al, 'w'
    je .set_up
    cmp al, 's'
    je .set_down
    cmp al, 'a'
    je .set_left
    cmp al, 'd'
    je .set_right
    jmp .no_key

.set_up:
    cmp byte [direction], 3
    je .no_key
    mov byte [direction], 0
    jmp .no_key
.set_down:
    cmp byte [direction], 0
    je .no_key
    mov byte [direction], 3
    jmp .no_key
.set_left:
    cmp byte [direction], 2
    je .no_key
    mov byte [direction], 1
    jmp .no_key
.set_right:
    cmp byte [direction], 1
    je .no_key
    mov byte [direction], 2
    jmp .no_key

.no_key:
    call delay_ticks

    ; 保存旧尾部
    xor ax, ax
    mov al, [snake_len]
    dec al
    mov si, ax
    mov al, [snake_x + si]
    mov [old_tail_x], al
    mov al, [snake_y + si]
    mov [old_tail_y], al

    ; 计算新头
    mov al, [snake_x]
    mov bl, [snake_y]
    mov cl, [direction]
    cmp cl, 0
    je .up
    cmp cl, 1
    je .left
    cmp cl, 2
    je .right
    inc bl              ; 3 = down
    jmp .calc_done
.up:
    dec bl
    jmp .calc_done
.left:
    dec al
    jmp .calc_done
.right:
    inc al
.calc_done:
    mov [new_head_x], al
    mov [new_head_y], bl

    ; 撞墙
    cmp al, 1
    jl .game_over
    cmp al, 78
    jg .game_over
    cmp bl, 1
    jl .game_over
    cmp bl, 23
    jg .game_over

    ; 吃食物
    cmp al, [food_x]
    jne .no_food
    cmp bl, [food_y]
    jne .no_food

    cmp byte [snake_len], 50
    jae .no_food

    ; ---- 吃到食物 ----
    xor cx, cx
    mov cl, [snake_len]
    dec cl
    mov si, cx
.shift_grow:
    test si, si
    jz .shift_grow_done
    mov al, [snake_x + si - 1]
    mov [snake_x + si], al
    mov al, [snake_y + si - 1]
    mov [snake_y + si], al
    dec si
    jmp .shift_grow
.shift_grow_done:
    mov al, [new_head_x]
    mov [snake_x], al
    mov al, [new_head_y]
    mov [snake_y], al
    inc byte [snake_len]
    inc byte [score_val]
    xor ax, ax
    mov al, [snake_len]
    dec al
    mov si, ax
    mov al, [old_tail_x]
    mov [snake_x + si], al
    mov al, [old_tail_y]
    mov [snake_y + si], al
    call spawn_food
    jmp .move_done

.no_food:
    xor cx, cx
    mov cl, [snake_len]
    dec cl
    mov si, cx
.shift:
    test si, si
    jz .shift_done
    mov al, [snake_x + si - 1]
    mov [snake_x + si], al
    mov al, [snake_y + si - 1]
    mov [snake_y + si], al
    dec si
    jmp .shift
.shift_done:
    mov al, [new_head_x]
    mov [snake_x], al
    mov al, [new_head_y]
    mov [snake_y], al

.move_done:
    call clear_screen
    call draw_food
    call draw_snake

    ; 自身碰撞
    xor cx, cx
    mov cl, [snake_len]
    mov si, cx
.self_check:
    dec si
    test si, si
    jz .game_loop
    mov al, [snake_x + si]
    cmp al, [snake_x]
    jne .not_self
    mov al, [snake_y + si]
    cmp al, [snake_y]
    je .game_over
.not_self:
    jmp .self_check

.quit_game:
    jmp 0x0000:0x7E00

.game_over:
    call beep_game_over
    mov si, msg_game_over
    call print_str
    mov si, msg_score
    call print_str
    mov al, [score_val]
    call print_num
    xor ah, ah
    int 0x16
    jmp 0x0000:0x7E00