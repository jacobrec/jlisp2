#include <stdio.h>
#include <math.h>


#include "symboltable.h"
#include "bin/tokens.c"
#include "vm.h"
#include "types.h"

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
    t.f64 = 1.0; p(t);
    t.f64 = sqrt(-1.0); p(t);
    t.f64 = -0.0 / 0.0; p(t);
    t.f64 = log(0.0) + 1.0 / 0.0; p(t);
    t.f64 = log(0.0) * 0.0; p(t);
    t = jlisp_uint48(49); p(t);
    t = jlisp_uint48(1302942); p(t);
    t = jlisp_int32(2147483647); p(t);
    t = jlisp_int32(-1302942); p(t);
    t = jlisp_true(); p(t);
    t = jlisp_false(); p(t);
    t = jlisp_nil(); p(t);
    t = jlisp_pointer(1); p(t);


}
