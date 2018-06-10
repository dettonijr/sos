asm("jmp boot_main\n");

#include <stdint.h>

uint8_t inb(uint16_t port){
	uint8_t ret;
    asm volatile ( 
		"inb %1, %0;"
        : "=a"(ret)
        : "d"(port) 
    );
    return ret;
}

void outb(uint16_t port, uint8_t data) {
    asm volatile (
        "outb %1, %0;"
        :
        : "d" (port), "a" (data)
    );
}

void memset(unsigned char* mem, unsigned char c, int n) {
    while(n--) {
        *mem = c;
        mem++;
    }
}

void memcpy(unsigned char* dst, unsigned char* src, int n) {
    while(n--) {
        *dst = *src;
        dst++;
        src++;
    }
}

void reverse_inplace(unsigned char* mem, int n) {
    unsigned char* end = mem + n - 1;
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

    void print(const char* str) {
        if (!str) return;

        while(*str) {
            putchar(*str++);
        }
    }
    
    void println(const char* str = 0x0) {
        print(str);
        new_line();
    }

    void print(int n) {
        char str[20];
        for(int i = 0; i < 20; i++) str[i] = 0;
        int i = 0;
        while(n) {
            str[i] = (n%10) + '0';
            i++;
            n /= 10; 
        }
        reverse_inplace((unsigned char*) str, i);
        print(str);
    }

    // Goes to new line and scrolls
    void new_line() {
        if (y < LEN_Y - 1) {
            y++;
            x = 0;
        } else {
            for (int i = 0; i < LEN_Y - 1; i++) {
                auto line_index = LEN_X * i;
                auto line = &mem_buffer[line_index];
                auto next_line = &mem_buffer[line_index + LEN_X];
                memcpy((unsigned char*) line, (unsigned char*) next_line, sizeof(*mem_buffer) * LEN_X);
            }
            y = LEN_Y - 1;
            x = 0;
        }
    }

    void set(int x, int y) {
        this->x = x;
        this->y = y;
    }

    void clear() {
        memset((unsigned char*) mem_buffer, 0, LEN_X*LEN_Y*sizeof(uint16_t));
    }

};


extern "C" void __attribute__((noreturn)) boot_main() {
    Terminal t;
    t.clear();
    t.print(10);
    t.println();
    t.println("haha");
    for(int i = 0; i < 80; i++)
        t.putchar(i);
    t.set(0,2);
    const char* msg = "abcdef";
    t.println(msg);
    t.println(msg);
    t.println(msg);
    for(int i = 0; i < 10000; i++) {
        t.print(i);
        t.println();
    }
    for(;;);
}
