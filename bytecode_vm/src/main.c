#include <stdio.h>
#include <stdlib.h>
#include <math.h>


#include "symboltable.h"
#include "tokens.h"
#include "vm.h"
#include "types.h"
#include "stack.h"
#include "memory.h"

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
    t = jlisp_pointer(NULL+1); stack_push(stack, t);
    t = jlisp_cons(jlisp_int32(-5), jlisp_string("end")); stack_push(stack, t);
    t = jlisp_string("Hello"); stack_push(stack, t);
    t = jlisp_symbol(strdup("Hellosym")); stack_push(stack, t);
    t = jlisp_int32(3); stack_push(stack, t);

    while (stack->size > 0) {
        t = stack_pop(stack);
        p(t);
    }

    stack_free(stack);

    struct VM vm;
    init_vm(&vm);
    // (+ 1 2)
    char data[] = {1, 1, 1, 2, 2, 3};
    run(&vm, data, 6);

    // "hello"
    char data2[] = {0, 6, 72, 101, 108, 108, 111, 0, 3};
    run(&vm, data2, 9);

    // ((fn (x y) (+ x y)) 40 9)
    char data3[] = {7, 6, 72, 101, 108, 108, 111, 0, // start function named "hello"
                    2, //arity
                    6, // bytes in body
                    6, 0, //load first arg
                    6, 1, // load second arg
                    2, // add args
                    5, // return
                    // end of function
                    1, 40, 1, 9, // load the 2 args [40], and [9]
                    15, /*<-Arg count. Fn name ->*/ 6, 72, 101, 108, 108, 111, 0,
                    4, 2,/*<-Arg count. Fn name ->*/
                    // [4]^ call function named hello, with 2 args
                    3 // end
    };
    run(&vm, data3, 31);

    // (if false "true" 'false)
    char data4[] = {
        0x0C, // load false
        0x09, 0x09, // JMPF[9]
        0x00, 0x05, 0x74, 0x72, 0x75, 0x65, 0x00, // load "true"
        0x08, 0x08,
        0x0e, 0x06, 0x66, 0x61, 0x6C, 0x73, 0x65, 0x00, // load 'false
        0x03 // end
    };
    run(&vm, data4, 21);

    // (if true "true" 'false)
    char data5[] = {
        0x0B, // load true
        0x09, 0x09, // JMPF[9]
        0x00, 0x05, 0x74, 0x72, 0x75, 0x65, 0x00, // load "true"
        0x08, 0x08,
        0x0e, 0x06, 0x66, 0x61, 0x6C, 0x73, 0x65, 0x00, // load 'false
        0x03 // end
    };
    run(&vm, data5, 21);

    // ((fn (x) x) 5)
    char data6[] = {
        0x07, 0x08, 0x66, 0x6e, 0x3b, 0x74, 0x65, 0x73, 0x74, 0x00,
        0x1, // arity
        0x03, // body length
        0x06, 0x00, /*local 0*/ 0x05,/*return*/ // function body
        0x01, 0x05, // arg 1
        0x0F, 0x08, 0x66, 0x6e, 0x3b, 0x74, 0x65, 0x73, 0x74, 0x00, // load function by name
        0x04, 0x01, // call [n]
        0x03 // end
    };
    run(&vm, data6, 30);

}
