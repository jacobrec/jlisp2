#include <stdio.h>
#include <math.h>


#include "symboltable.h"
#include "bin/tokens.h"
#include "vm.h"
#include "types.h"
#include "stack.h"

int printbits (uint64_t d) {
    for (int i = 64; i > 0; i--) {
        printf ("%ld", (d >> (i-1)) & 1);
        if ((64-i) == 0) {printf(" ");}
        if ((64-i) == 11) {printf(" ");}
    }
    printf ("   ");
    return 0;
}

int main() {
    if(NULL != 0) {
        exit(1);
    }
    enum token tok;
    tok = STRING1;

    printf("Hello, World: %s\n", token_to_string(tok));

    printf("%d %d %d\n", intern_symbol("hi"), intern_symbol("hello"), intern_symbol("hi"));

#define p(t) (printbits(t.data), printf("%s: [%s]\n", jlisp_typeof(t), jlisp_value_to_string(t)))
    union jlisp_type t;
    struct stack* stack = stack_init();

    t.f64 = 1.0; stack_push(stack, t);
    t.f64 = sqrt(-1.0); stack_push(stack, t);
    t.f64 = -0.0 / 0.0; stack_push(stack, t);
    t.f64 = log(0.0) + 1.0 / 0.0; stack_push(stack, t);
    t.f64 = log(0.0) * 0.0; stack_push(stack, t);
    t = jlisp_uint48(49); stack_push(stack, t);
    t = jlisp_uint48(1302942); stack_push(stack, t);
    t = jlisp_int32(2147483647); stack_push(stack, t);
    t = jlisp_int32(-1302942); stack_push(stack, t);
    t = jlisp_true(); stack_push(stack, t);
    t = jlisp_false(); stack_push(stack, t);
    t = jlisp_nil(); stack_push(stack, t);
    t = jlisp_pointer(1); stack_push(stack, t);

    while (stack->size > 0) {
        t = stack_pop(stack);
        p(t);
    }

    stack_free(stack);
}
