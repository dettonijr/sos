; This is used only as an entry point to the C code

bits 16
EXTERN boot_main 

call boot_main
hlt
