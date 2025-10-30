.model large

LOCALS @@
;include fileF.asm
;EXTERN open_file: proc

.stack 100h



.data

exit_key db 05h


debug   db  "EXIT" , 0Dh, 0Ah, '$'

arg1    db  0
arg2    db  0
arg3    db  0
arg4    db  255 dup(' ')


arg5    dw  0
arg6    dw  0
arg7    dw  0


arg8    db  0
arg9    db  0
arg10   db  255 dup(' ')


inp_len db 0
max_len db 71


max_system_len db 73;?72
max_output_len db 70


current_screen_line_off dw 0
previous_screen_line_off dw 0
sum_screen_line_off dw  0



file_name   db 63 dup(0)
substring_to_find   db 63 dup(0)

start_find  dw  0
end_find    dw  0



current_edit_position   dw  0
current_line_edit_offset    dw  0



image_size  dw  0
temp_image_size dw 0

is_first_print_one db 0

posX    db  5
posY    db  2

posMinL db  5
posMinH db  2
posMaxL db  74
posMaxH db  18


tempPosX    db  0
tempPosY    db  0


error_flag  db 0
is_first db 1
is_end db   0
is_endline  db  0


filePointer dw  0




upperLine   db  "/----------------------------------------------------------------------\", '0'
midleLine   db  "|----------------------------------------------------------------------|", '0'
downLine    db  "\----------------------------------------------------------------------/", '0'
emptyLine   db  "                                                                      ", '0'

openedCorrect   db  "Opened", '0'
saveCorrect db  " Saved", '0'
openedError   db  "Error", '0'

crtlE   db  " CTRL + E/EXIT |", '0'
ctrlS   db  " CTRL + S/SAVE |", '0'
ctrlO   db  " CTRL + O/OPEN |", '0'
ctrlF   db  " CTRL + F/FIND |", '0'



openMessage db  60 ;//Lenght
            db  5  ;//Height

            
            buffer  db 64000 dup('0') 

.code





print   macro   string
    mov ax, @data
    mov ds, ax
    mov dx, offset string
    mov ah ,9
    int 21h
endm


print_one    macro   inp1
    mov arg1, inp1
    call print_one_main
endm

print_zero_line macro   string, maxlen_inp
    push ax
    mov ah, maxlen_inp
    mov max_len, ah
    pop ax
    
    lea si, string
    call printLineZ
endm



print_offset_zero_line  macro   string, maxlen_inp
    push ax
    mov ah, maxlen_inp
    mov max_len, ah
    pop ax
    
    lea si, string
    call printLineZ
endm

; args1 - dh, args2 - dl
print_without_off  macro  args1, args2, string, maxlen_inp

    push ax
    mov ah, args1
    mov arg8, ah
    mov ah, args2
    mov arg9, ah
    pop ax
    
    push ax
    mov ah, maxlen_inp
    mov max_len, ah
    pop ax
    
    lea si, string
    call zero_off_print
endm



set_input_pos   macro   x, y
    mov arg2, x
    mov arg3, y
    call set_input_pos_main
endm



    


;//Procedure code section




write_to_file   proc
    
    push ax bx cx dx
    
    
    mov dx, offset file_name
    mov cx, 0
    mov ah, 3Ch
    int 21h
    mov filePointer,ax
    
    mov dx, offset buffer
    mov cx, 0
    lea si, buffer
    
    @@forloop:
        cmp byte ptr[si], '0'
        je @@breakloop
        inc si
        inc cx
        jmp @@forloop
        
    @@breakloop:
    mov bx, filePointer
    mov ah, 40h
    int 21h
    
    mov bx, filePointer
    mov ah, 3Eh
    int 21h
    
    
    pop dx cx bx ax
    ret

write_to_file   endp

first_line_len  proc
    
    lea di, buffer
    add di, sum_screen_line_off
    
@@printZ:
    mov al, byte ptr[di]
    cmp al, 0Dh
    je @@check2
    jmp @@nextNotEq
    
@@check2:
    inc di
    mov al, byte ptr[di]
    cmp al, 0Ah
    je @@nextL
    
    dec di
    jmp @@nextNotEq
    
    
@@nextL:
    add current_screen_line_off, 2
    jmp @@end_count
    
    
@@nextNotEq:
    inc current_screen_line_off
    inc di
    
@@endPrint:  
    cmp current_screen_line_off, 70
    je @@end_count
    jmp @@nothingOver
    
@@nothingOver:
    
    cmp byte ptr[di],'0'
    je @@end_count
    
    jmp @@printZ
    
    
@@end_count:
    ret
first_line_len  endp



shift_one   proc

    lea si, buffer
    add si, current_edit_position
    
    
    @@forloop:
        cmp byte ptr[si], '0'
        je @@loopend
        inc cx
        inc si
        jmp @@forloop
        
    @@loopend:
    
    lea si, buffer
    add si, current_edit_position
    add si, cx
    
    lea di ,buffer
    add di, current_edit_position
    add di, cx
    inc di
    
    
    inc cx
    
    std
    rep movsb
    
    
    ret

shift_one endp


shift_back  proc

    lea si, buffer
    add si, current_edit_position
    
    
    @@forloop:
        cmp byte ptr[si], '0'
        je @@loopend
        inc cx
        inc si
        jmp @@forloop
        
    @@loopend:
    
    
    lea si, buffer
    add si, current_edit_position
    inc si        
    
    lea di ,buffer
    add di, current_edit_position
    
    
    
    inc cx
    cld
    rep movsb
    
    
    ret
shift_back  endp


prefirst_line_len   proc

    mov previous_screen_line_off, 0
    cmp sum_screen_line_off, 0
    je @@return_final
    
    lea di, buffer
    add di, sum_screen_line_off
    
    inc previous_screen_line_off
    dec di
    cmp byte ptr[di], 0Ah
    je @@true
    jmp @@false
    
    @@true:
    dec di
    inc previous_screen_line_off
    
        @@loopy:
        cmp byte ptr[di], 0Ah
        je @@return
        
        cmp di, offset buffer
        je @@return_final
        
        dec di
        inc previous_screen_line_off
        jmp @@loopy
        
    @@false:
    mov previous_screen_line_off, 71
@@return:
    dec previous_screen_line_off
    
@@return_final:

    @@whilemore:
    cmp previous_screen_line_off, 70
    jg @@decrement
    jmp endwhile@@
    @@decrement:
        sub previous_screen_line_off, 70
        jmp @@whilemore
    
    endwhile@@:
        

ret

prefirst_line_len   endp


printLineZ  proc
    add si,sum_screen_line_off 
printZ:
    mov cx, 1 
    mov ah, 09h
    mov al, byte ptr[si]
    
    cmp al, 0Dh
    je check2
    jmp nextNotEq
    
check2:
    inc si
    mov al, byte ptr[si]
    cmp al, 0Ah
    je nextL
    
    dec si
    mov al, byte ptr[si]
    jmp nextNotEq
    
    
nextL:
    cmp image_size, 16
    je end_print
    inc image_size
    inc dh
    inc si
    mov dl, 5
    mov ah, 02h
    int 10h
    mov inp_len, 0
    jmp printZ
    
    
nextNotEq:
    
    int 10h
    inc si
    inc inp_len
    inc dl
endPrint:
    mov ah, 02h
    int 10h
    
    mov ah, max_len
    
    cmp inp_len, ah
    je nexLineOver

    jmp nothingOver
    
nexLineOver:
    cmp image_size, 16
    je end_print
    inc image_size
    
    inc dh
    mov dl, 5
    mov ah, 02h
    int 10h
    cmp image_size, 16
    jne next_printZ
    mov inp_len, 0
    jmp nothingOver
next_printZ:
    
    mov inp_len, 0
    
nothingOver:
    
    cmp byte ptr[si],'0'
    je end_print
    
    jmp printZ
    
    
end_print:
    
    mov is_end, 0
    cmp byte ptr[si],'0'
    jne @@false
    mov is_end, 1
    @@false:
    mov inp_len, 0
    mov image_size,0
    mov temp_image_size, 0
    ret
printLineZ  endp


set_edit_screen proc
    mov dl, 4
    mov dh, 1
    mov ah, 2
    int 10h

    print_zero_line upperLine, max_system_len
    
    mov dh, 2
    mov dl, 4
    
edit_loop:
    mov ah, 2
    int 10h
    
    
    mov cx, 72
    mov ah, 09h
    mov al, ' '
    int 10h
    
    
    inc dh
    cmp dh, 23
    jb  edit_loop
    
    
    mov dh, 21
    mov dl, 4
    mov ah, 02h
    int 10h
    
    print_zero_line midleLine, max_system_len
    
    mov dh, 19
    mov dl, 4
    mov ah, 02h
    int 10h
    print_zero_line midleLine, max_system_len
    
    mov dh, 2
border_loop:
    mov dl, 4
    mov ah, 2
    int 10h
    
    
    mov cx, 1
    mov ah, 09h
    mov al, '|'
    int 10h
    
    mov dl, 75
    mov ah, 2
    int 10h
    
    mov cx, 1
    mov ah, 09h
    mov al, '|'
    int 10h
    
    
    inc dh
    cmp dh, 23
    jb border_loop
    
    mov dl, 4
    mov ah, 2
    int 10h
    print_zero_line downLine, max_system_len
    
    
    
    
    
    
    
    
    ret
set_edit_screen endp





zero_off_print  proc
    mov ax, sum_screen_line_off
    push ax
    mov al, is_end
    push ax
    mov sum_screen_line_off, 0
    
    mov dh, arg8
    mov dl, arg9
    mov ah, 02h
    int 10h
    push bx
    mov bl, 12h
    
    ;print_zero_line
    call printLineZ
    
    pop bx
    
    
    pop ax
    mov is_end, al
    pop ax
    mov sum_screen_line_off,ax
    
    ret
zero_off_print  endp




clear_screen    proc
    mov dh, 2
    mov dl, 5
@@edit_loop:
    
    mov ah, 2
    int 10h
    
    
    mov cx, 70
    mov ah, 09h
    mov al, ' '
    int 10h
    
    
    inc dh
    cmp dh, 19
    jb  @@edit_loop
clear_screen    endp



set_border_screen   proc

    mov dl, 3
    mov dh, 2
    mov ah, 02h
    int 10h
    
    mov ah, 09h
    mov al, '/'
    ret
    

set_border_screen   endp


set_input_pos_main   proc

    mov dh, arg2
    mov dl, arg3
    mov ah, 2
    int 10h
    ret

set_input_pos_main   endp

set_ctrl    proc


    mov dh, 22
    mov dl, 5
    
    mov ah, 02h
    int 10h
    
    print_zero_line crtlE,max_output_len
    print_zero_line ctrlS,max_output_len
    print_zero_line ctrlO,max_output_len
    print_zero_line ctrlF,max_output_len
    
    ret

set_ctrl    endp



tab_print proc


    mov dl, posX
    add dl, 4
    cmp dl, posMaxL
    jge end_tab
    
    mov dl, posX
    mov dh, posY

    mov cx, 4
    mov ah, 09h
    mov al, ' '
    int 10h
    
    add posX, 4
    mov dl, posX
    
    
    mov ah, 02h
    int 10h
   
    
end_tab:
    ret

tab_print endp


move_up proc


    push sum_screen_line_off
    push previous_screen_line_off
    
    mov ax, current_line_edit_offset
    mov sum_screen_line_off, ax
    
    call prefirst_line_len
    
    mov ax, previous_screen_line_off
    sub current_line_edit_offset, ax
    
    pop previous_screen_line_off
    pop sum_screen_line_off
        
    sub current_edit_position, ax
    
    
    
    
    mov dh, posY
    mov dl, posX

    cmp dh, posMinH
    jne up
    jmp short end_up
    
up:
    dec dh
    mov ah,2
    int 10h
    
    mov posY, dh
    jmp close_up
    

end_up:
    mov posY, dh
    mov posX, dl
    call prefirst_line_len
    mov ax, previous_screen_line_off
    sub sum_screen_line_off, ax
    call clear_screen
    mov dl, 5
    mov dh, 2
    mov ah, 02h
    int 10h
    print_offset_zero_line buffer, max_output_len
    
    mov dh, posY
    mov dl, posX
    mov ah, 02h
    int 10h
close_up:
    ret
    
move_up endp


up_check_main   proc
    push bx
    mov ax ,current_line_edit_offset
    cmp ax, 0
    je @@return
    
    
    call move_up
    
    lea di , buffer
    mov bx,  current_line_edit_offset
    
    cmp byte ptr[di + bx], 0Dh
    jne @@forlpop
    inc bx
    jmp @@true
    
    @@forlpop:
        cmp byte ptr[di + bx], 0Dh
        je @@true
        
        cmp bx, current_edit_position
        jg @@true
        
        inc bx
        jmp @@forlpop
        
    
    
    @@true:
    dec bx
    mov current_edit_position, bx
    
    sub bx, current_line_edit_offset
    
    xor bh,bh
    mov dl, bl
    add dl ,5
    mov posX, dl
    mov ah, 02h
    int 10h
    
    @@return:
    pop bx
    ret
    
    
up_check_main   endp


move_right_fileN  proc
    
    mov dh, posY
    mov dl, posX
    cmp dl, posMaxL
    je @@end_right
    
    mov ah,2
    inc dl
    int 10h
    
    mov posX, dl
    
@@end_right:
    ret

move_right_fileN  endp
    

move_right  proc
    
    mov dh, posY
    mov dl, posX
    cmp dl, posMaxL
    je end_right
    
    mov ah,2
    inc dl
    int 10h
    
    mov posX, dl
    
end_right:
    ret

move_right  endp


move_left   proc


    mov dh, posY
    mov dl, posX

    cmp dl, posMinL
    jne left
    jmp short end_left

left:
    dec dl
    mov ah,2
    int 10h
    mov posX, dl
end_left:
    ret
move_left   endp



move_down   proc
   
    cmp is_end, 1
    jne @@next1
    
    mov dh, posY
    cmp dh, posMaxH
    je check1
    
    @@next1:
    
    push sum_screen_line_off
    push current_screen_line_off
    
    mov ax, current_line_edit_offset
    mov sum_screen_line_off, ax
    
    call first_line_len
    
    mov ax, current_screen_line_off
    add current_line_edit_offset, ax
    
    pop current_screen_line_off
    pop sum_screen_line_off
    
    ;mov ax, current_line_edit_offset
    
    add current_edit_position, ax
    
check1:
    cmp is_end, 1
    jne @@next
    
    mov dh, posY
    cmp dh, posMaxH
    je close_end
    
    @@next:

    mov dh, posY
    mov dl, posX

    cmp dh, posMaxH
    jne down
    jmp short end_down

down:
    
    
    
    inc dh
    mov ah,2
    int 10h
    mov posY, dh
    jmp close_end
    
end_down:
    mov posY, dh
    mov posX, dl
    cmp is_end, 1
    je close_end
    
    
    call first_line_len
    
    mov ax, current_screen_line_off
    add sum_screen_line_off, ax
    
    mov current_screen_line_off, 0
    
    call clear_screen
    mov dl, 5
    mov dh, 2
    mov ah, 02h
    int 10h
    print_offset_zero_line buffer, max_output_len
    mov dh, posY
    mov dl, posX
    mov ah, 02h
    int 10h
close_end:
    
    ret
move_down   endp



down_check_main    proc
    push bx
    call move_down
    
    lea di, buffer
    mov bx, current_line_edit_offset
    
    cmp byte ptr[di + bx], 0Dh
    jne @@forllop
    inc bx
    jmp @@breakloop
    
    @@forllop:
        cmp bx, current_edit_position
        jg @@breakloop
        
        cmp byte ptr[di + bx], 0Dh
        je @@breakloop
        
        inc bx
        jmp @@forllop
            
    
        @@breakloop:
            dec bx
            mov current_edit_position, bx
            
            sub bx, current_line_edit_offset
            xor bh,bh
            mov dl, bl
            add dl, 5
            mov posX, dl
            mov dh ,posY
            
            mov ah, 02h
            int 10h
    
    @@return:
    pop bx
    ret
down_check_main    endp


end_line   proc
    mov ax, current_line_edit_offset
    
    call shift_one
    inc current_edit_position
    call shift_one
    lea si, buffer
    add si, current_edit_position
    mov byte ptr[si], 0Ah
    dec si
    mov byte ptr[si], 0Dh
    
    inc current_edit_position
    
    mov dh, posY
    cmp dh, posMaxH
    jne @@next1
    mov current_edit_position, ax
    call move_down
    dec dh
    jmp @@next2
    
    @@next1:
    
    mov ax, current_edit_position
    mov current_line_edit_offset, ax
    
    @@next2:
    
    inc dh
    mov posY, dh
    mov ah,posMinL
    mov posX, ah
    
end_eline:
    
    call clear_screen
    mov dl, 5
    mov dh, 2
    mov ah, 02h
    int 10h
    print_offset_zero_line buffer, max_output_len
    mov dh, posY
    mov dl, posX
    mov ah, 02h
    int 10h
    ret

end_line   endp


print_one_main  proc

    

    mov cx, 1
    mov al, arg1
    mov ah, 09h
    int 10h
   
    call move_right
    ;call move_right_fileN
    ret

print_one_main endp



delete  proc


    push sum_screen_line_off
    push previous_screen_line_off
    
    mov ax, current_line_edit_offset
    mov sum_screen_line_off, ax
    
    call prefirst_line_len
    
    mov ax, previous_screen_line_off
    
    pop previous_screen_line_off
    pop sum_screen_line_off
    
    
    dec current_edit_position
    lea si, buffer
    add si, current_edit_position
    mov dh, posY
    mov dl, posX
    
    cmp byte ptr[si], 0Dh
    jne @@next
    
    @@next:
    
    ;if1
    cmp byte ptr[si], 0Ah
    jne @@next_delete
    
    sub current_line_edit_offset, ax
    sub ax,2
    
    call shift_back
    dec current_edit_position
    call shift_back
    
    
    xor ah,ah
    mov posX ,al
    add posX, 5
    dec posY
    
    jmp @@clear_out
    
    @@next_delete:
    ;if2
    
    push ax
    mov ax, current_edit_position
    inc ax
    cmp ax, current_line_edit_offset
    jne @@next_delete1
    
    sub current_line_edit_offset, 70
    call shift_back
    ;dec current_edit_position
    dec posY
    mov posX, 74 
    
    pop ax
    jmp @@clear_out
    ;endif2
    
    @@next_delete1:
    pop ax
    call shift_back
    ;inc current_edit_position
    
    
    dec posX
    mov ah, 2
    int 10h
    
    @@clear_out:  
    call clear_screen
    mov dl, 5
    mov dh, 2
    mov ah, 02h
    int 10h
    print_offset_zero_line buffer, max_output_len
    mov dh, posY
    mov dl, posX
    mov ah, 02h
    int 10h
    
    mov posX, dl

end_delete:
    
    ret
delete  endp


set_pos_XY  proc

    mov dl, tempPosX
    mov dh, tempPosY
    
    mov posX, dl
    mov posY, dh
    
    mov ah, 02h
    int 10h
    ret

set_pos_XY  endp


;//Open, Close Files procedures
open_file   proc
    push si

    mov dx, offset file_name
    mov ah, 3Dh
    mov al, 00h
    int 21h
    jc open_error
    mov bx,ax
    
read_data:
    mov cx, 64000
    mov dx, offset buffer
    mov ah, 3Fh
    int 21h
    jc open_error
    mov cx, ax
    ;jcxz close_file
    
    lea si, buffer
    add si, cx
    mov byte ptr[si], '0'
    
    jmp close_file
    
    
open_error:
    mov error_flag, 1
    
close_file:
    mov ah, 3Eh
    int 21h
    
    
    pop si
    ret
open_file   endp

   
select_find_mark    proc
    push di
    push si
    
    mov ah, posY
    mov al, posX
    push ax
    
    mov dh, tempPosY
    mov dl, tempPosX
    mov posX, dl
    mov posY, dh
    mov ah, 02h
    int 10h
    
    
    call up_check_main
        push bx
        xor bh,bh
        mov bl, 00011111b
        call clear_screen
        mov dl, 5
        mov dh, 2
        mov ah, 02h
        int 10h
        print_zero_line buffer, max_output_len
        pop bx
    
    mov ax, end_find
    sub ax, current_line_edit_offset
    
    
    mov dl, al
    add dl, 5
    mov dh, posY
    mov ah, 02h
    int 10h
    
    mov posX, dl
    
    lea si, buffer
    add si, end_find
    
    push bx
    mov bl, 63
     
    @@forloop:
        mov ax, start_find
        cmp ax, end_find
        jg @@breakloop
        
        mov al, byte ptr[si]
         
        cmp dl, 4 ;posMinL - 1
        jne @@next2
        mov dl, posMaxL
        mov posX, dl
        dec dh
        dec posY
        mov ah, 02h
        int 10h
        print_one al
        dec dl
        mov ah, 02h
        int 10h
        dec si
        inc start_find
        jmp @@forloop
        
        ;dec si
        ;inc start_find 
        @@next2:
        
        print_one al
     
        dec si
        inc start_find
        sub posX, 2
        sub dl, 2
        mov ah, 02h
        int 10h
        
        jmp @@forloop
    
    
    @@breakloop:
    pop bx
    
    @@return:
    mov is_first_print_one, 0
    call down_check_main
    
    pop ax
    mov posX, al
    mov posY, ah
    pop si
    mov dh, posY
    mov dl, posX
    mov ah, 02h
    int 10h
    pop di
    
    ret
    
select_find_mark    endp
 
    
screen_find_validate    proc
    push di

    
    mov ah, posY
    mov al, posX
    push ax
    
    mov dh, tempPosY
    mov dl, tempPosX
    mov ah, 02h
    int 10h
    mov posY, dh
    mov posX, dl
    
    

    mov ax, end_find
    ;mov ax, start_find
    cmp ax, current_line_edit_offset
    jle @@to_zero
    jmp @@forloop
    
    @@to_zero:
        mov current_line_edit_offset, 0
        mov current_edit_position, 0
        mov posX, 5
        mov posY, 2
        mov dl, 5
        mov dh, 2
        mov ah, 02h
        int 10h
        
        mov current_screen_line_off, 0
        mov previous_screen_line_off, 0
        mov sum_screen_line_off,   0
        mov tempPosY, 2
        mov tempPosX, 5
        
        push bx
        xor bh,bh
        mov bl, 00011111b
        call clear_screen
        mov dh, 2
        mov dl, 5 
        mov ah, 02h
        int 10h
        print_zero_line buffer, max_output_len
        pop bx
    
    @@forloop:
    mov ax, end_find
    ;mov ax, start_find
    cmp ax, current_line_edit_offset
    jg @@above
    jmp @@before
    
    
    @@above: 
    push bx
    xor bh,bh
    mov bl, 00011111b

    call down_check_main
    ;call move_down
    
    pop bx
    ;call move_down
    
    mov dh, posY
    mov dl, posX
    mov tempPosY, dh
    mov tempPosX, dl
    
    jmp @@forloop
    
    
    @@before:
    
    
    
    @@return:
    
    pop ax
    mov posX, al
    mov posY, ah
    mov dh, posY
    mov dl, posX
    mov ah, 02h
    int 10h
    pop di
    
    ret

screen_find_validate    endp    


substring_to_find_clear  proc

    push si
    
    lea si, substring_to_find
    mov cx, 62
    @@forloop:
    mov byte ptr[si], 0
    inc si
    loop @@forloop
    
    pop si
    ret

substring_to_find_clear  endp


substring_find_main proc
    push si
    push di
    push cx

    lea si, buffer
    add si, start_find
    
    lea di, substring_to_find
    
    mov cx, 0
    @@forloop1:
    cmp byte ptr[di], 0
    je @@breakfor
    inc cx
    inc di
    jmp @@forloop1
    
@@breakfor:
    lea di, substring_to_find
    inc cx
    
    
    
@@forloop:
    mov al, byte ptr[si]
    
    cmp al, '0'
    je @@EOF
    
    cmp al, byte ptr[di]
    je @@check
    @@check_false:
    
    inc si
    jmp @@forloop
    
    @@check:
    push cx
    cld
    repe cmpsb
    cmp cx, 0
    je @@true
    jmp @@false
    
    
    
        @@true:
            pop cx
            mov end_find, si
            mov start_find, si
            sub start_find, cx
            sub end_find, offset buffer
            sub start_find, offset buffer
            dec end_find
            dec end_find
            jmp @@return
    
    
        @@false:
            mov ax, cx
            
            pop cx
            push cx
            
            sub cx, ax
            
            sub si, cx
            sub di, cx
            pop cx
            jmp @@check_false
        
     
    
@@EOF: 
    mov end_find, 0
    mov start_find, 0
    
    
@@return:
    
    pop cx
    pop di
    pop si
    ret
    
substring_find_main endp

    ;// CTRL procedures: EXIT/SAVE/OPEN/FIND
    
find    proc

    mov dl, posX
    mov dh, posY
    
    mov tempPosX, dl
    mov tempPosY, dh
    
    
    push bx
    mov bl, 74h
    mov dh, 22
    mov dl, 53
    
    mov ah, 02h
    int 10h
    
    mov ax,sum_screen_line_off
    push ax
    mov sum_screen_line_off,0
    mov al, is_end
    push ax
    print_zero_line ctrlF, max_output_len
    pop ax
    mov is_end, al
    pop ax
    mov sum_screen_line_off, ax
    
    
find_wait:
    mov cx, 0
    mov dx, 1000
    mov ah, 86h
    int 15h


    xor ah,ah
    int 16h
    
    
    
    cmp ah, 1Ch
    je @@new_window
    
    cmp ah, 01h
    je @@return_base_1
    
    jmp find_wait
    
    
@@new_window:
    lea di, substring_to_find
    
    pop bx
    mov dh, 20
    mov dl, 5
    mov ah, 02h
    int 10h
   
    mov ax,sum_screen_line_off
    push ax
    mov sum_screen_line_off,0
    mov al, is_end
    push ax
    print_zero_line emptyLine, max_output_len
    pop ax
    mov is_end, al
    pop ax
    mov sum_screen_line_off, ax
    
    push bx
    
    mov dh, 20
    mov dl, 5
    mov ah, 02h
    int 10h
    
    mov posX, dl
    mov posY, dh
    
    @@forn:
    mov cx, 0
    mov dx, 1000
    mov ah, 86h
    int 15h
    
    xor ah,ah
    int 16h
    
    cmp ah, 4Bh
    je @@forn
    
    cmp ah, 4Dh
    je @@forn
    
    cmp ah, 0Eh
    je @@delete_symb_find
    
    cmp ah, 1Ch
    je @@return_find
    
    cmp ah, 50h
    je @@forn
    
    cmp ah, 48h
    je @@forn
    
    cmp ah, 0Fh
    je @@forn
    
    cmp ah, 01h
    je @@return
    
    jmp @@print_input_key_find
    
    ;Long jump
    @@return_base_1:
    jmp @@return
    
@@print_input_key_find:

    mov bl, 12h
    print_one al
    mov byte ptr[di], al
    inc di
    mov end_find, 0
    mov start_find, 0
    jmp @@forn
        
   
@@delete_symb_find:
    
    cmp di, offset substring_to_find
    je @@forn
    
    mov end_find, 0
    mov start_find, 0
    
    mov bl, 12h
    mov byte ptr[di], 0
    dec di
    
    mov dh, 20
    dec posX
    mov dl, posX
    mov ah, 02h
    int 10h
    print_one ' '
    mov dh, 20
    dec posX
    mov dl, posX
    mov ah, 02h
    int 10h
    
    jmp @@forn
    
@@return_find:
    call substring_find_main
    
    call screen_find_validate
    cmp end_find, 0
    je @@return_find1
    
    call select_find_mark
    
    @@return_find1:
    
    mov ax, end_find
    mov start_find, ax
    
    jmp @@forn

@@return:
    call substring_to_find_clear
    mov end_find, 0
    mov start_find, 0
    mov dh, 22
    mov dl, 53
    
    mov ah, 02h
    int 10h
    pop bx
    mov ax,sum_screen_line_off
    push ax
    mov sum_screen_line_off,0
    mov al, is_end
    push ax
    print_zero_line ctrlF, max_output_len
    pop ax
    mov is_end, al
    pop ax
    mov sum_screen_line_off, ax
    call set_pos_XY
    ret
find    endp



    
exit    proc
    mov dl, posX
    mov dh, posY
    
    mov tempPosX, dl
    mov tempPosY, dh
    
    
    push bx
    mov bl, 74h
    
    mov dh, 22
    mov dl, 5
    
    mov ah, 02h
    int 10h
    mov ax, sum_screen_line_off
    push ax
    mov sum_screen_line_off,0
    
    mov al, is_end
    push ax
    print_zero_line crtlE, max_output_len
    pop ax
    mov is_end, al
    pop ax
    mov sum_screen_line_off, ax
exit_wait:
    
    mov cx, 0
    mov dx, 1000
    mov ah, 86h
    int 15h


    xor ah,ah
    int 16h
    cmp ah, 01h
    je return_main
    
    cmp ah, 1Ch
    je exit_final
    
    jmp exit_wait
    
return_main:
    ;print_one 0Ah
    ;print debug
    mov dh, 22
    mov dl, 5
    
    mov ah, 02h
    int 10h
    pop bx
    
    mov ax, sum_screen_line_off
    push ax
    mov sum_screen_line_off,0
    
    mov al, is_end
    push ax
    print_zero_line crtlE, max_output_len
    pop ax
    mov is_end, al
    pop ax
    mov sum_screen_line_off, ax
    
    call set_pos_XY
    ret
    
exit_final:
    mov ax, 0003h
    int 10h
    mov ax, 4C00h
    int 21h
exit endp


save    proc
    mov dl, posX
    mov dh, posY
    
    mov tempPosX, dl
    mov tempPosY, dh
    
    push bx
    mov bl, 74h
    mov dh, 22
    mov dl, 21
    
    mov ah, 02h
    int 10h
    
    
    mov ax, sum_screen_line_off
    push ax
    mov sum_screen_line_off,0
    
    mov al, is_end
    push ax
    print_zero_line ctrlS, max_output_len
    pop ax
    mov is_end, al
    pop ax
    mov sum_screen_line_off, ax
    
save_wait:
    
    mov cx, 0
    mov dx, 1000
    mov ah, 86h
    int 15h


    xor ah,ah
    int 16h
    cmp ah, 01h
    je return_main_save
    
    cmp ah, 1Ch 
    je write
    
    jmp save_wait
    
    
write:
    call write_to_file
    
    print_without_off 20, 69, saveCorrect, max_output_len
    
    mov dh, 25
    mov ah,02h
    int 10h
    
    jmp save_wait
    
return_main_save:
    
    print_without_off 20, 69, openedCorrect, max_output_len
    
    mov dh, 22
    mov dl, 21
    
    mov ah, 02h
    int 10h
    pop bx
    mov ax, sum_screen_line_off
    push ax
    mov sum_screen_line_off,0
    
    mov al, is_end
    push ax
    print_zero_line ctrlS, max_output_len
    pop ax
    mov is_end, al
    pop ax
    mov sum_screen_line_off, ax
    call set_pos_XY
    ret
    
save    endp


open    proc
    mov dl, posX
    mov dh, posY
    
    mov tempPosX, dl
    mov tempPosY, dh
    
    push bx
    mov bl, 74h
    mov dh, 22
    mov dl, 37
    
    mov ah, 02h
    int 10h
    
    
    print_zero_line ctrlO, max_output_len
    
open_wait:
    
    mov cx, 0
    mov dx, 1000
    mov ah, 86h
    int 15h


    xor ah,ah
    int 16h
    
    
    cmp ah, 1Ch
    je new_window
    
    cmp ah, 01h
    je return_inp_1
    
    jmp open_wait
    
new_window:
    lea di, file_name
    
    pop bx
    mov dh, 20
    mov dl, 5
    mov ah, 02h
    int 10h
    print_zero_line emptyLine, max_output_len
    push bx
    
    
    mov dh, 20
    mov dl, 5
    mov ah, 02h
    int 10h
    
    mov posX, dl
    mov posY, dh
forn:
    mov cx, 0
    mov dx, 1000
    mov ah, 86h
    int 15h
    
    xor ah,ah
    int 16h
    
    cmp ah, 4Bh
    je move_left_line_inp
    
    cmp ah, 4Dh
    je move_right_line_inp
    
    cmp ah, 0Eh
    je delete_symb_inp
    
    cmp ah, 1Ch
    je return_inp
    
    cmp ah, 50h
    je forn
    
    cmp ah, 48h
    je forn
    
    cmp ah, 0Fh
    je forn
    
    cmp al, ' '
    je forn
    
    jmp print_input_key_inp
    
print_input_key_inp:
    
    mov bl, 12h
    print_one al
    mov [di], al
    inc di
    jmp forn
    
return_inp_1:
    jmp return_main_open
    
move_left_line_inp:
    ;call move_left
    jmp forn

move_right_line_inp:
    ;call move_right
    jmp forn
    
delete_symb_inp:
    cmp di, offset file_name
    je forn
    
    mov bl, 12h
    mov byte ptr[di], 0
    dec di
    
    mov dh, 20
    dec posX
    mov dl, posX
    mov ah, 02h
    int 10h
    print_one ' '
    mov dh, 20
    dec posX
    mov dl, posX
    mov ah, 02h
    int 10h
    
    jmp forn
    
return_inp:
    jmp return_main_open
    
return_main_open:
    call open_file
    mov dh, 22
    mov dl, 37
    mov ah, 02h
    int 10h
    
    pop bx
    print_zero_line ctrlO, max_output_len
    push bx
    cmp error_flag, 0
    je true
    jmp false
true:
    mov dh, 20
    mov dl, 69
    mov ah, 02h
    int 10h
    
    push bx
    mov bl, 12h
    print_zero_line openedCorrect, max_output_len
    pop bx
    set_input_pos 2,5
    pop bx
    print_offset_zero_line buffer, max_output_len
    mov posX, 5
    mov posY, 2
    mov dl, 5
    mov dh, 2
    mov ah, 02h
    int 10h
    
    jmp short end_open
    
false:
    mov error_flag, 0
    mov dh, 20
    mov dl, 69
    mov ah, 02h
    int 10h
    
    mov bl, 14h
    print_zero_line openedError, max_output_len
    pop bx
    mov posX,5
    mov posY,2 
    mov dh,2
    mov dl,5
    mov ah, 02h
    int 10h
end_open:
    ret
    
open    endp


right_check_main    proc

    
    lea di, buffer
    add di, current_edit_position
    
    cmp byte ptr[di], 0Dh
    je @@return
    
    cmp byte ptr[di], '0'
    je @@return
    
    inc current_edit_position
    inc di
    
    cmp byte ptr[di], 0Ah
    je @@return_true
    
    mov dl, posX
    cmp dl, posMaxL
    je @@return_true
    
    call move_right
    jmp @@return
    
    
    @@return_true:
    dec current_edit_position
    
    @@return:
    ret
right_check_main    endp



left_check_main proc


    mov dl, posX
    cmp dl, posMinL
    je @@return

    dec current_edit_position
    
    call move_left
    
    @@return:
    ret
    
left_check_main endp


step    proc
    
    call move_down
    mov posX, 5
    mov ax, current_line_edit_offset
    mov current_edit_position, ax
    
    call clear_screen
    mov dl, 5
    mov dh, 2
    mov ah, 02h
    int 10h
    print_offset_zero_line buffer, max_output_len
    
    mov dh, posY
    mov dl, posX
    mov ah, 02h
    int 10h
    mov is_endline, 0
    ret
step    endp


input_key   proc

    lea di, buffer
    add di, current_edit_position
    cmp byte ptr[di], 0Dh
    jne @@next
    call shift_one
    @@next:
    
    cmp byte ptr[di], '0'
    jne @@next3
    call shift_one
    @@next3:
    
    mov cl, posMaxL
    cmp posX, cl
    jne @@next1
    mov is_endline, 1
    @@next1:
    
    print_one al
    
    lea di, buffer
    add di, current_edit_position
    mov byte ptr[di], al
    inc current_edit_position
    
    cmp is_endline, 1
    jne @@next2
    call step
    @@next2:
    
    ret

input_key   endp







;//Main code section
start:

    mov ax, @data
    mov ds, ax
    mov es, ax
  

    mov ax, 0003h
    int 10h

    mov dx, 0
    mov bl, 00011111b

    call set_edit_screen
    call set_ctrl

    mov dl, posX
    mov dh, posY
    mov ah, 02h
    int 10h
    
    


main_cycle:

    mov cx, 0
    mov dx, 1000
    mov ah, 86h
    int 15h


    xor ah,ah
    int 16h
    cmp ah, 48h
    je move_up_line
    
    cmp ah, 4Bh
    je move_left_line
    
    cmp ah, 50h
    je move_down_line
    
    cmp ah, 4Dh
    je move_right_line
    
    cmp ah, 0Eh
    je delete_symb
    
    cmp ah, 0Fh
    je tab_input
    
    cmp al, 06h
    je find_main
    
    cmp al, 13h
    je save_main
    
    cmp al, 05h
    je exit_main
    
    cmp al, 0Fh
    je open_main
    
    cmp al, 0Dh
    je next_line
    
    jmp print_input_key
    

next_line:
    call end_line
    jmp main_cycle

    
print_input_key:
    call input_key
    jmp main_cycle

    
move_up_line:
    ;call move_up
    call up_check_main
    jmp main_cycle
    
move_left_line:
    ;dec current_edit_position
    ;call move_left
    call left_check_main
    jmp main_cycle

move_right_line:
    ;inc current_edit_position
    ;call move_right
    call right_check_main
    jmp main_cycle
    
move_down_line:
    ;call move_down
    call down_check_main
    jmp main_cycle
    
delete_symb:
    call delete
    jmp main_cycle
    
tab_input:
    call tab_print
    jmp main_cycle
    
exit_main:
    call exit
    jmp main_cycle
    
save_main:
    call save
    jmp main_cycle
    
open_main:
    call open
    jmp main_cycle
    
find_main:
    call find
    jmp main_cycle
    
no_key_pressed:
     
    end start