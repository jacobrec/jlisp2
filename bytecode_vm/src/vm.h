#pragma once

#include <stdint.h>

#include "stack.h"
#include "insert_hash.h"

struct VM {
    struct stack* stack;
    char* data;
    uint32_t ip; // instruction pointer
    uint32_t fp; // frame pointer
    uint32_t args; // number of args in current function
    uint32_t data_size;
    struct insert_table* function_addresses; // hashtable that maps names to addresses
    struct insert_table* function_arities; // hashtable that maps names to arities
};

void init_vm(struct VM* vm);
void run(struct VM* vm, char* data, int length);
