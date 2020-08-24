#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "vm.h"
#include "types.h"
#include "tokens.h"

#define DEBUG
#ifdef DEBUG
#define DPRINT(...) printf(__VA_ARGS__)
#else
#define DPRINT(...) 0
#endif

void init_vm(struct VM* vm) {
    vm->data = NULL;
    vm->data_size = 0;
    vm->ip = 0;
    vm->stack = stack_init();
}
void run(struct VM* vm, char* data, int length) {
    // add new data
    vm->data_size += length;
    vm->data = realloc(vm->data, vm->data_size);
    memcpy(vm->data + vm->data_size - length, data, length);

    // actually run
#define NEXT() (DPRINT("%d ", vm->data[vm->ip]), vm->data[vm->ip++])
    while(true) {
        enum token v = NEXT();
        DPRINT("-> %s ", token_to_string(v));
        switch(v) {
        case STRING1: {
            int chars = NEXT();
            char str[chars];
            for (int i = 0; i < chars; i++) {
                str[i] = NEXT();
            }
            // TODO: make strings a jlisp type
            break;
        }
        case INT1: {
            stack_push(vm->stack, jlisp_int32(NEXT()));
            break;
        }
        case ADD2: {
            jlisp_type tl = stack_pop(vm->stack);
            jlisp_type tr = stack_pop(vm->stack);
            stack_push(vm->stack, jlisp_int32((tl.data & BITS32) + (tr.data & BITS32)));
            break;
        }
        case END: {
            jlisp_type t = stack_pop(vm->stack);
            printf("stack top = %s: [%s]\n", jlisp_typeof(t), jlisp_value_to_string(t));
            puts("Done");
            return;
        }
        }
        DPRINT("\n");
    }
}
