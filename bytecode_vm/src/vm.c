#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <assert.h>

#include "vm.h"
#include "types.h"
#include "tokens.h"
#include "insert_hash.h"

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
    vm->fp = 0;
    vm->stack = stack_init();
    vm->function_addresses = insert_table_init();
}

#define NEXT() (DPRINT("%d ", vm->data[vm->ip]), vm->data[vm->ip++])
#define POP() stack_pop(vm->stack)
#define PUSH(val) stack_push(vm->stack, (val))

// TODO: dont leak memory
int next_string1(struct VM* vm, char** res) {
    int chars = NEXT();
    char* str = malloc(chars);
    for (int i = 0; i < chars; i++) {
        str[i] = NEXT();
    }
    *res = str;
    return chars;
}


void run(struct VM* vm, char* data, int length) {
    // add new data
    vm->data_size += length;
    vm->data = realloc(vm->data, vm->data_size);
    memcpy(vm->data + vm->data_size - length, data, length);

    // actually run
    while(true) {
        enum token v = NEXT();
        DPRINT("-> %s ", token_to_string(v));
        switch(v) {
        case STRING1: {
            char* str;
            next_string1(vm, &str);
            // TODO: strings are currently a memory leak
            PUSH(jlisp_string(str));
            break;
        }

        case INT1: {
            PUSH(jlisp_int32(NEXT()));
            break;
        }

        case ADD: {
            jlisp_type tl = POP();
            jlisp_type tr = POP();
            PUSH(jlisp_int32((tl.data & BITS32) + (tr.data & BITS32)));
            break;
        }

        case END: {
            jlisp_type t = POP();
            printf("<<%s: [%s]>>\n", jlisp_typeof(t), jlisp_value_to_string(t));
            return;
        }

        case CALL: {
            int args = NEXT();

            jlisp_type fn_ptr = POP();
            // TODO: check type, differnt things if closure

            int fp = vm->fp;
            int ip = vm->ip;
            int av = vm->args;

            vm->fp = vm->stack->size - args;
            vm->args = args;
            vm->ip = fn_ptr.data & BITS32;

            assert(vm->ip != 0);
            PUSH(jlisp_uint48(ip));
            PUSH(jlisp_uint48(fp));
            PUSH(jlisp_uint48(av));
            break;
        }

        case RETURN: {
            jlisp_type return_value = POP();
            jlisp_type ipd = vm->stack->data[vm->fp + vm->args];
            jlisp_type fpd = vm->stack->data[vm->fp + vm->args + 1];
            jlisp_type avd = vm->stack->data[vm->fp + vm->args + 2];
            stack_popn(vm->stack, vm->stack->size - vm->fp);
            vm->fp = fpd.data & BITS48;
            vm->ip = ipd.data & BITS48;
            vm->args = avd.data & BITS48;
            printf("<<%s: [%s]>>\n", jlisp_typeof(return_value), jlisp_value_to_string(return_value));
            PUSH(return_value);

            break;
        }

        case LOCAL: {
            int n = NEXT();
            PUSH(vm->stack->data[vm->fp + n]);
            break;
        }

        case FUNCTION: {
            char* str;
            next_string1(vm, &str);
            int arity = NEXT();
            int bytes = NEXT();
            insert_table_add(vm->function_addresses, str, vm->ip);
            vm->ip += bytes;
            break;
        }

        case JMP: {
            int jmp = NEXT();
            vm->ip += jmp;
            break;
        }

        case JMPF: {
            jlisp_type value = POP();
            int jmp = NEXT();
            if (is_jlisp_nil(value) || is_jlisp_false(value)) {
                DPRINT("[JUMPING %d]", jmp);
                vm->ip += jmp;
            }
            break;
        }

        case JMPT: {
            jlisp_type value = POP();
            int jmp = NEXT();
            if (!(is_jlisp_nil(value) || is_jlisp_false(value))) {
                vm->ip += jmp;
            }
            break;
        }

        case TRUE:  {PUSH(jlisp_true()); break;}
        case FALSE: {PUSH(jlisp_false()); break;}
        case NIL:   {PUSH(jlisp_nil()); break;}

        case SYMBOL1: {
            char* str;
            next_string1(vm, &str);
            PUSH(jlisp_symbol(str));
            break;
        }

        case FUNCTION_POINTER: {
            char* str;
            next_string1(vm, &str);
            uint32_t loc = insert_table_lookup(vm->function_addresses, str);
            PUSH(jlisp_function(loc));
            break;
        }

        }
        DPRINT("\n");
    }
}
