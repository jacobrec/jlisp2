#pragma once

#include "types.h"
struct stack {
    jlisp_type* data;
    int size;
    int capacity;
};

struct stack* stack_init();
void stack_push(struct stack* s, jlisp_type t);
jlisp_type stack_pop(struct stack* s);
jlisp_type stack_popn(struct stack* s, int n);
void stack_free(struct stack* s);


