#pragma once

#include <stdint.h>

#include "stack.h"

struct VM {
    struct stack* stack;
    char* data;
    uint32_t ip;
    uint32_t data_size;
};

void init_vm(struct VM* vm);
void run(struct VM* vm, char* data, int length);
