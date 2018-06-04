asm(".code16gcc\n");
asm("jmp boot_main\n");

#include <stdint.h>

void memset(unsigned char* mem, unsigned char c, int n) {
    while(n--) {
        *mem = c;
        mem++;
    }
}

void reverse_inplace(unsigned char* mem, int n) {
    unsigned char* end = mem + n;
    unsigned char* start = mem;
    while(end > start) {
        char tmp = *end;
        *end = *start;
        *start = tmp;
        --end;
        ++start;
    }
}

void itos(char* out, int n) {
    int i = 0;
    while(n) {
        out[i] = (n%10) + '0';
        i++;
        n /= 10; 
    }
    reverse_inplace((unsigned char*)out, i);
}

void itoh(char* out, int n) {
    const char* hex="0123456789ABCDEF";
    int i = 0;
    while(n) {
        int index = n & 0x0f;
        out[i] = hex[index];
        i++;
        n >>= 4; 
    }
    reverse_inplace((unsigned char*)out, i);
}

class Terminal {
    static const int LEN_X = 80;
    static const int LEN_Y = 25;
   
    int x;
    int y;
    
    uint16_t* mem_buffer;

public:
    Terminal(uint16_t* addr = (uint16_t*)0xB8000) : mem_buffer(addr), x(0), y(0) {}

    void putchar(char a) {
        mem_buffer[y*LEN_X+x] = 0x0F00 + a;
        x++;
        x %= LEN_X;
    }

    void println(const char* str) {
        while(*str) {
            putchar(*str++);
        }
        y++;
        x = 0;
    }

    void set(int x, int y) {
        this->x = x;
        this->y = y;
    }

    void clear() {
        memset((unsigned char*) mem_buffer, 0, LEN_X*LEN_Y*sizeof(uint16_t));
    }

};

void f(const char* msg){
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
void kernel_main(void);
extern "C" void __attribute__((noreturn)) boot_main() {
    Terminal t;
    t.clear();
    for(int i = 0; i < 80; i++)
        t.putchar(i);
    t.set(0,2);
    const char* msg = "abcdef";
    t.println(msg);
    t.println(msg);
    t.println(msg);
    for(;;);
}
