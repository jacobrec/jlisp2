#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <assert.h>

#include "symboltable.h"
#include "types.h"
#include "memory.h"

jlisp_type jlisp_car_cdr(jlisp_type cons, bool iscar) {
    if (is_jlisp_cons(cons) || is_jlisp_closure(cons)) {
        struct jlisp_cons_cell* cell = ((struct jlisp_cons_cell*) (cons.data & BITS48));
        return iscar ? cell->car : cell->cdr;
    } else {
        printf("Cannot take %s of non cons\n", iscar ? "car" : "cdr");
        assert(0);
    }
}
jlisp_type jlisp_car(jlisp_type cons) {
    jlisp_car_cdr(cons, true);
}
jlisp_type jlisp_cdr(jlisp_type cons) {
    jlisp_car_cdr(cons, false);
}

jlisp_type jlisp_closure(jlisp_type function, jlisp_type nfree, jlisp_type freeptr) {
    jlisp_type t = jlisp_cons(function, jlisp_cons(nfree, freeptr));
    uint64_t ptr = t.data & BITS48;
    t.data = TYPE(BITS_CLOSURE) | ptr;
    return t;
}
bool is_jlisp_closure(jlisp_type data) {
    return IS_TYPE(data.data, BITS_CLOSURE);
}

jlisp_type jlisp_cons(jlisp_type car, jlisp_type cdr) {
    jlisp_type t = jlisp_allocate();
    uint64_t ptr = t.data & BITS48;

    struct jlisp_cons_cell* cell = ((struct jlisp_cons_cell*) ptr);
    cell->car = car;
    cell->cdr = cdr;

    t.data = TYPE(BITS_CON_PTR) | ptr;
    return t;
}
bool is_jlisp_cons(jlisp_type data) {
    return IS_TYPE(data.data, BITS_CON_PTR);
}

jlisp_type jlisp_function(uint32_t addr) {
    jlisp_type t;
    t.data = TYPE(BITS_FUN_PTR) | (addr & BITS32);
    return t;
}
bool is_jlisp_function(jlisp_type data) {
    return IS_TYPE(data.data, BITS_FUN_PTR);
}


jlisp_type jlisp_nil() {
    jlisp_type t;
    t.data = SPECIAL(BITS_SPECIAL_NIL);
    return t;
}
bool is_jlisp_nil(jlisp_type data) {
    return SPECIAL(BITS_SPECIAL_NIL) == data.data;
}

jlisp_type jlisp_true() {
    jlisp_type t;
    t.data = SPECIAL(BITS_SPECIAL_TRUE);
    return t;
}
bool is_jlisp_true(jlisp_type data) {
    return SPECIAL(BITS_SPECIAL_TRUE) == data.data;
}

jlisp_type jlisp_false() {
    jlisp_type t;
    t.data = SPECIAL(BITS_SPECIAL_FALSE);
    return t;
}
bool is_jlisp_false(jlisp_type data) {
    return SPECIAL(BITS_SPECIAL_FALSE) == data.data;
}

jlisp_type jlisp_uint48(uint64_t data) {
    jlisp_type t;
    t.data = TYPE(BITS_UNSIGNED_INT) | (data & BITS48);
    return t;
}
bool is_jlisp_uint48(jlisp_type data) {
    return IS_TYPE(data.data, BITS_UNSIGNED_INT);
}

jlisp_type jlisp_int32(int32_t data) {
    jlisp_type t;
    uint32_t* d = &data;
    t.data = TYPE32(BITS_32_INT) | *d;
    return t;
}
bool is_jlisp_int32(jlisp_type data) {
    return IS_TYPE32(data.data, BITS_32_INT);
}

jlisp_type jlisp_symbol(char* sym) {
    jlisp_type t;
    uint32_t loc = intern_symbol(sym);
    free(sym);
    t.data = TYPE32(BITS_32_SYM) | loc;
    return t;
}
bool is_jlisp_symbol(jlisp_type data) {
    return IS_TYPE32(data.data, BITS_32_SYM);
}

jlisp_type jlisp_pointer(void* data) {
    assert(data != NULL); // use jlisp nil instead
    assert(data == ((uint64_t)data & BITS48));
    jlisp_type t;
    t.data = TYPE(BITS_POINTER) | ((uint64_t)data & BITS48);
    return t;
}
bool is_jlisp_pointer(jlisp_type data) {
    return IS_TYPE(data.data, BITS_POINTER) && (data.data & BITS48) != 0;
}

jlisp_type jlisp_string(char* data) {
    assert(data != NULL); // use jlisp nil instead
    assert(data == ((uint64_t)data & BITS48));
    jlisp_type t;
    t.data = TYPE(BITS_STR_PTR) | ((uint64_t)data & BITS48);
    return t;
}
bool is_jlisp_string(jlisp_type data) {
    return IS_TYPE(data.data, BITS_STR_PTR) && (data.data & BITS48) != 0;
}

char* jlisp_typeof(jlisp_type t) {
    if (is_jlisp_nil(t)) {
        return "nil";
    } else if (is_jlisp_true(t)) {
        return "true";
    } else if (is_jlisp_false(t)) {
        return "false";
    } else if (is_jlisp_uint48(t)) {
        return "uint48";
    } else if (is_jlisp_int32(t)) {
        return "int32";
    } else if (is_jlisp_string(t)) {
        return "string";
    } else if (is_jlisp_cons(t)) {
        return "cons";
    } else if (is_jlisp_closure(t)) {
        return "closure";
    } else if (is_jlisp_function(t)) {
        return "function";
    } else if (is_jlisp_pointer(t)) {
        return "pointer";
    } else if (is_jlisp_symbol(t)) {
        return "symbol";
    } else {
        return "double";
    }
}

// TODO: have this return a jlisp_type and not memory leak
char* jlisp_value_to_string(jlisp_type t) {
    if (is_jlisp_nil(t)) {
        return "nil";
    } else if (is_jlisp_true(t)) {
        return "true";
    } else if (is_jlisp_false(t)) {
        return "false";
    } else if (is_jlisp_uint48(t)) {
        char* s;
        asprintf(&s, "%lu", t.data & BITS48);
        return s;
    } else if (is_jlisp_int32(t)) {
        char* s;
        asprintf(&s, "%d", t.data & BITS32);
        return s;
    } else if (is_jlisp_string(t)) {
        return (char*)(t.data & BITS48);
    } else if (is_jlisp_symbol(t)) {
        char* s;
        asprintf(&s, "sym:%u", t.data & BITS32);
        return s;
    } else if (is_jlisp_cons(t)) {
        char* s;
        char* car = jlisp_value_to_string(jlisp_car(t));
        char* cdr = jlisp_value_to_string(jlisp_cdr(t));
        asprintf(&s, "(%s . %s)", car, cdr);
        return s;
    } else if (is_jlisp_closure(t)) {
        return "closure";
    } else if (is_jlisp_function(t)) {
        return "function";
    } else if (is_jlisp_pointer(t)) {
        return "pointer";
    } else {
        char* s;
        asprintf(&s, "%f", t.f64);
        return s;
    }
}
