#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <assert.h>

#include "types.h"


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
    t.data = TYPE(BITS_SIGNED_INT) | *d;
    return t;
}
bool is_jlisp_int32(jlisp_type data) {
    return IS_TYPE(data.data, BITS_SIGNED_INT);
}

jlisp_type jlisp_pointer(void* data) {
    assert(data != NULL); // use jlisp nil instead
    jlisp_type t;
    t.data = TYPE(BITS_POINTER) | ((uint64_t)data & BITS48);
    return t;
}
bool is_jlisp_pointer(jlisp_type data) {
    return IS_TYPE(data.data, BITS_POINTER) && (data.data & BITS48) != 0;
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
    } else if (is_jlisp_pointer(t)) {
        return "pointer";
    } else {
        return "double";
    }
}

// TODO: have this return a jlisp_type
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
        asprintf(&s, "%ld", t.data & BITS32);
        return s;
    } else if (is_jlisp_pointer(t)) {
        return "pointer";
    } else {
        char* s;
        asprintf(&s, "%f", t.f64);
        return s;
    }
}
