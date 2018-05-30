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
    push bx
  
    mov bx, ax
    mov ah, 0x2     ; Operation READ
    mov al, 10      ; Sectors to read
    mov ch, 0       ; Cylinder
    mov cl, 2       ; Sector
    mov dh, 0       ; Head
    mov dl, 0       ; Drive
    int 13h

    pop bx
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
 
    START_MSG db "Loading...", 10, 0
    times 510-($-$$) db 0  ; fill sector w/ 0's
    dw 0xAA55        ; req'd by some BIOSes
