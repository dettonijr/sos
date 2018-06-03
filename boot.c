asm(".code16gcc\n");
asm("jmp boot_main\n");

void
f(const char* msg){
    char c; 
    while(*msg) {
		asm(
			"mov %0, %%al;"
			"mov $0x0E, %%ah;"
			"int $0x10;"
			:
			: "r" (*msg)
		);
        msg++;
	}
}   

void __attribute__((noreturn)) boot_main() {
    char* msg = "abcdef";
    f(msg);

    for(;;);
}
