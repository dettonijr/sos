; Bootloader
; The binary should be exactly 512 bytes long
; This is used only to load the rest of the code 

ORG 0x7c00 
BITS 16

; Just after the bootloader
KERNEL_ADDRESS equ 0x7E00 

jmp start

; This procedure loads the next sectors into memory
; AX = Memory location to load
load_kernel:
    pusha
 
    mov bx, ax
    mov ah, 0x2     ; Operation READ
    mov al, 10      ; Sectors to read
    mov ch, 0       ; Cylinder
    mov cl, 2       ; Sector
    mov dh, 0       ; Head
    ; mov dl, 0       ; Drive
    ; Assuming drive is already in dl
    int 13h

    shr ax, 8
    cmp ax, 0
    je .end
    .error:
    ; Save our result in cx
    mov cx, ax

    mov ax, ERROR_MSG
    call print

    ; Print first char
    mov bx, HEX_CHARS
    mov ax, cx
    shr ax, 4
    and ax, 0x000f
    add bx, ax
    mov al, [bx]
    call print_char
 
    ; Print second char
    mov bx, HEX_CHARS
    mov ax, cx
    and ax, 0x000f
    add bx, ax
    mov al, [bx]
    call print_char

    mov al, 13
    call print_char
    mov al, 10 
    call print_char
 
    .end:
    popa
    ret

; AL = Contains the char to be printed
print_char:
    mov ah, 0Eh 
    int 10h
    ret

; AX = Pointer to string to be printed
print:
    ; Save context
    push bx

    mov bx, ax ; We need ax for the interrupt
    mov ah, 0Eh 

    .start:
    mov al, [bx]
    cmp al, 0
    je .end
    int 10h
    inc bx
    jmp .start

    .end:
    ; Restore context    
    pop bx 
    ret

start:
    mov ax, START_MSG
    call print

    mov ax, KERNEL_ADDRESS
    call load_kernel

    ; Bye bye, never come back
    jmp KERNEL_ADDRESS
 
    START_MSG db "Loading...", 13, 10, 0
    ERROR_MSG db "ERROR ", 0
    HEX_CHARS db "0123456789abcdef"
    times 510-($-$$) db 0  ; fill sector w/ 0's
    dw 0xAA55        ; req'd by some BIOSes
