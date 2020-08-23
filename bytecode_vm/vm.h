#pragma once

#include <stdint.h>

struct VM {
    char* data;
    uint32_t ip;
    uint32_t data_size;
};

void init_vm(struct VM* vm);
void run(struct VM* vm, char* data, int length);
