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

    cli
    lgdt [gdt_pointer] ; load the gdt table
    mov eax, cr0 
    or eax,0x1 ; set the protected mode bit on special CPU reg cr0
    mov cr0, eax
    jmp CODE_SEG:long_jmp

bits 32
long_jmp:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Bye bye, never come back
    jmp KERNEL_ADDRESS

CODE_SEG equ 8 ; Entry 1 (first 3 bits are ignored)
DATA_SEG equ 16 ; Entry 2

; We define 2 entries in the GDT. For data and code
; Both start at base 0x0 and limit 0x0fffff (1<<20 - 1 _ 1mb)
; Granularity is set to 4kb pages
; So the segments go from 0x00000000 to 0xffffffff
; That is the whole memory
; After this, we can pretend we have a flat memory of 4GB

gdt_pointer:
    dw 3*8  ; size of gdt 3 entries of 8 bytes 
    dd gdt_start  ; pointer to gdt
gdt_start:
    db 0,0,0,0,0,0,0,0
gdt_code:
    db 0xff ; lowest byte of Limit
    db 0xff ; next byte of Limit
    db 0x00 ; lowest byte of Base Addr
    db 0x00 ; next byte of Base Addr
    db 0x00 ; third byte of Base Addr
    db 10011010b ; 1 - Present 
                 ; 00 - Privilege 
                 ; 1 - System
                 ; 1010 Type
    db 11001111b ; 1 - Granularity: Pages of 4kb
                 ; 1 - 32 bit mode
                 ; 0 - Reserved
                 ; 0 - Available
                 ; 1111 Highest bytes of limit
    db 0x00 ; fourth and highest byte of Base Addr 
gdt_data:
    db 0xff ; lowest byte of Limit
    db 0xff ; next byte of Limit
    db 0x00 ; lowest byte of Base Addr
    db 0x00 ; next byte of Base Addr
    db 0x00 ; third byte of Base Addr
    db 10010010b ; 1 - Present 
                 ; 00 - Privilege 
                 ; 1 - System
                 ; 0010 Type
    db 11001111b ; 1 - Granularity: Pages of 4kb
                 ; 1 - 32 bit mode
                 ; 0 - Reserved
                 ; 0 - Available
                 ; 1111 Highest bytes of limit
    db 0x00 ; fourth and highest byte of Base Addr 
    
    START_MSG db "Loading...", 13, 10, 0
    ERROR_MSG db "ERROR ", 0
    HEX_CHARS db "0123456789abcdef"
    times 510-($-$$) db 0  ; fill sector w/ 0's
    dw 0xAA55        ; req'd by some BIOSes
