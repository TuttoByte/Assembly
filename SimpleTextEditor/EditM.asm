.model large

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


file_name   db 63 dup(0)
file_name_test  db  "i.txt",0

posX    db  5
posY    db  2

posMinL db  5
posMinH db  2
posMaxL db  74
posMaxH db  18


tempPosX    db  0
tempPosY    db  0


error_flag  db 0



upperLine   db  "/----------------------------------------------------------------------\", '0'
midleLine   db  "|----------------------------------------------------------------------|", '0'
downLine    db  "\----------------------------------------------------------------------/", '0'
emptyLine   db  "|                                                                      |", '0'

openedCorrect   db  "Opened", '0'
openedError   db  "Error", '0'

crtlE   db  " CTRL + E/EXIT |", '0'
ctrlS   db  " CTRL + S/SAVE |", '0'
ctrlO   db  " CTRL + O/OPEN |", '0'



openMessage db  60 ;//Lenght
            db  5  ;//Height

            
buffer  db ?  

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

print_zero_line macro   string
    lea si, string
    call printLineZ
endm



    


;//Procedure code section


printLineZ  proc
printZ:
    mov cx, 1 
    mov ah, 09h
    mov al, byte ptr[si]
    int 10h
    inc si
    
    inc dl
    mov ah, 2
    int 10h
    
    cmp byte ptr[si],'0'
    jne printZ
    
    ret
printLineZ  endp

set_edit_screen proc
    mov dl, 4
    mov dh, 1
    mov ah, 2
    int 10h

    print_zero_line upperLine
    
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
    
    print_zero_line midleLine
    
    mov dh, 19
    mov dl, 4
    mov ah, 02h
    int 10h
    print_zero_line midleLine
    
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
    print_zero_line downLine
    
    
    
    
    
    
    
    
    ret
set_edit_screen endp


set_border_screen   proc

    mov dl, 3
    mov dh, 2
    mov ah, 02h
    int 10h
    
    mov ah, 09h
    mov al, '/'
    ret
    

set_border_screen   endp


set_ctrl    proc


    mov dh, 22
    mov dl, 5
    
    mov ah, 02h
    int 10h
    
    print_zero_line crtlE
    print_zero_line ctrlS
    print_zero_line ctrlO
    
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
    

end_up:
    ret
    
move_up endp
    

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
    jmp short end_up

left:
    dec dl
    mov ah,2
    int 10h
    mov posX, dl
end_left:
    ret
move_left   endp



move_down   proc

    mov dh, posY
    mov dl, posX

    cmp dh, posMaxH
    jne down
    jmp short end_down

down:
    inc dh
    mov ah,2
    int 10h
    
end_down:
    mov posY, dh
    
    ret
move_down   endp


end_line   proc

    mov dh, posY
    cmp dh, posMaxH
    je end_eline

    inc dh
    mov ah,posMinL
    mov posX, ah
    mov dl, posX
    mov ah,2
    int 10h
    
    mov posY, dh
    
end_eline:
    ret

end_line   endp


print_one_main  proc

    

    mov cx, 1
    mov al, arg1
    mov ah, 09h
    int 10h
    
    
  
    call move_right
    
    ret

print_one_main endp



delete  proc

    
    mov dh, posY
    mov dl, posX
   
    cmp posMinL, dl
    je end_delete
    
    dec dl
    mov ah, 2
    int 10h
    ;dec dl
    
    mov cx, 1
    mov al, ' '
    mov ah, 9h
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
    mov cx, 30
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




;// CTRL procedures: EXIT/SAVE/OPEN
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
    print_zero_line crtlE
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
    print_zero_line crtlE
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
    print_zero_line ctrlS
    
save_wait:
    
    mov cx, 0
    mov dx, 1000
    mov ah, 86h
    int 15h


    xor ah,ah
    int 16h
    cmp ah, 01h
    je return_main_save 
    
    jmp save_wait
    
return_main_save:
    mov dh, 22
    mov dl, 21
    
    mov ah, 02h
    int 10h
    pop bx
    print_zero_line ctrlS
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
    print_zero_line ctrlO
    
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
    je return_main_open 
    
    jmp open_wait
    
new_window:
    lea di, file_name
    
    pop bx
    mov dh, 20
    mov dl, 4
    mov ah, 02h
    int 10h
    print_zero_line emptyLine
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
    cmp ah, 48h
    
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
    
move_left_line_inp:
    ;call move_left
    jmp forn

move_right_line_inp:
    ;call move_right
    jmp forn
    
delete_symb_inp:
    mov bl, 12h
    ;mov [di], 0
    ;dec di
    
    call delete
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
    print_zero_line ctrlO
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
    print_zero_line openedCorrect
    pop bx
    
    call set_pos_XY
    print_zero_line buffer
    jmp short end_open
    
false:
    mov dh, 20
    mov dl, 69
    mov ah, 02h
    int 10h
    
    push bx
    mov bl, 14h
    print_zero_line openedError
    pop bx
    
end_open:
    ret
    
open    endp




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
    print_one al
    jmp main_cycle

    
move_up_line:
    call move_up
    jmp main_cycle
    
move_left_line:
    call move_left
    jmp main_cycle

move_right_line:
    call move_right
    jmp main_cycle
    
move_down_line:
    call move_down
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
    
no_key_pressed:
     
    end start