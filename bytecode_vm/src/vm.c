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
            int fp = vm->fp;
            int ip = vm->ip;
            int av = vm->args;

            if (is_jlisp_function(fn_ptr)) {
                vm->fp = vm->stack->size - args;
                vm->args = args;
                vm->ip = fn_ptr.data & BITS32;
            } else if (is_jlisp_closure(fn_ptr)) {
                jlisp_type fun = jlisp_car(fn_ptr);
                jlisp_type nfree = jlisp_car(jlisp_cdr(fn_ptr));
                jlisp_type freeptr = jlisp_cdr(jlisp_cdr(fn_ptr));

                int nfreeint = (uint64_t)(BITS48 & nfree.data);
                args += nfreeint;
                jlisp_type* ptr = (jlisp_type*) (freeptr.data & BITS48);
                for (int i = 0; i < nfreeint; i++) {
                    PUSH(ptr[i]);
                }
                vm->fp = vm->stack->size - args;
                vm->args = args;
                vm->ip = fun.data & BITS32;
            } else {
                printf("cannot call with type %s\n", jlisp_typeof(fn_ptr));
                assert(0);
            }

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

        case MAKE_CLOSURE: {
            uint64_t args = NEXT();
            jlisp_type nfree = jlisp_uint48(args);
            jlisp_type fn = POP();
            jlisp_type* ptr = malloc(sizeof(jlisp_type) * args);
            jlisp_type freeptr = jlisp_pointer(ptr);
            for (int i = 0; i < args; i++) {
                ptr[i] = POP();
            }
            PUSH(jlisp_closure(fn, nfree, freeptr));
            break;
        }

        case CONS: {
            jlisp_type cdr = POP();
            jlisp_type car = POP();
            PUSH(jlisp_cons(car, cdr));
            break;
        }

        case CAR: {PUSH(jlisp_car(POP())); break;}
        case CDR: {PUSH(jlisp_cdr(POP())); break;}

        case POPSTACK: {
            jlisp_type pval = POP();
            printf("<<%s: [%s]>>", jlisp_typeof(pval), jlisp_value_to_string(pval));
            break;
        }

        }
        DPRINT("\n");
    }
}
