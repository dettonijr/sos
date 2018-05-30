__asm__(".code16\n");

void boot_main() {
    char* msg = "abcdef";
    char c; 
    while(c = *msg++) {
		asm(
			"mov %0, %%al;"
			"mov $0x0E, %%ah;"
			"int $0x10;"
			:
			: "r" (c)
		);
	}
}
