.model small
.stack 100h
include macro.asm
.486
.data
old_handler_offset dw ?
old_handler_seg dw ?
exit_flag db 0
timer dw 0
x_pos db 0
y_pos db 0
period dw 18        ; 1 секунд / 55 мс = 18.(18)
tick_count dw period

screen_attrib db 0
attrib db 00001010b
dots db ":", "$"
.code
timer_int proc far
    pusha

    inc tick_count
    mov ax, period
    cmp tick_count, ax
    jl skip_exit
    mov tick_count, 0


    ; очистка экрана
    dec attrib
    and attrib, 00001111b
    mov ah, 06h
    mov al, 00h
    mov bh, attrib
    mov cx, 0000h
    mov dx, 184fh
    int 10h

    ; двигаю курсор
    mov ah, 02h
    mov bh, 00h
    mov dl, x_pos
    mov dh, y_pos
    int 10h

    mov ah, 2Ch         ; получить время
    int 21h
    ; Return:
    ; CH = hour
    ; CL = minute
    ; DH = second
    ; DL = 1/100 seconds
    ; add ch, '0'
    xor ax, ax
    mov al, ch
    mWriteAX
    mWriteStr dots
    mov al, cl
    mWriteAX
    mWriteStr dots
    mov al, dh
    mWriteAX

    ; generate rand numbr
    xor dx, dx
    add al, cl
    add al, ch
    mov bx, 15485
    mul bx
    mul ax
    mul ax
    mul ax

    push ax
    xor dx, dx
    xor ah, ah
    mov bx, 80
    div bx
    mov x_pos, dl

    pop ax
    xor dx, dx
    mov al, ah
    xor ah, ah
    mov bx, 25
    div bx
    mov y_pos, al

    xor dx, dx
    xor ax, ax
    xor bx, bx

    mov ah, 1       ; Проверка, что какая-то кнопка нажата
    int 16h
    jz skip_exit    ; ничего не нажато

    mov ah, 0       ; Если что-то нажато, то надо узнать что
    int 16h

    cmp al, '0'     ; выход
    jnz skip_exit
exit:
    mov exit_flag, 1
skip_exit:
    popa
    iret
timer_int endp

start:
    mov ax, @data
    mov ds, ax

    ; получить адреса прерываний
    mov ah, 35h     ; получить вектор прерывания
    mov al, 1Ch     ; прерывание таймера
    int 21h
    ; в bx записался сдвиг старого прерывания
    ; в es записался сегмент старого прерывания

    mov old_handler_offset, bx
    mov old_handler_seg, es

    ; мое прерывание
    push ds

    ; возвразаем прерывание
    mov dx, offset timer_int
    mov ax, seg timer_int
    mov ds, ax

    mov ah, 25h     ; меняем вектор прерывания
    mov al, 1Ch     ; наше прерывание таймера
    int 21h

    mov ah, 01h
    mov cx, 2607h
    int 10h

    pop ds

_main_loop:
    cmp exit_flag, 1
    je _exit
    jmp _main_loop

_exit:
    ; надо вернуть всё как было
    mov dx, old_handler_offset
    mov ax, old_handler_seg
    mov ds, ax      ; можно поменять только через ax
 
    mov ah, 25h     ; поменятьменять вектор прерывания
    mov al, 1Ch     ; наше прерывание таймера
    int 21h

    mov ax, 4C00h
    int 21h
end start
