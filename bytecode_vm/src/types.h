#pragma once

#include <stdbool.h>
#include <stdint.h>


union jlisp_type {
    double f64;
    uint64_t data;
};
typedef union jlisp_type jlisp_type;

#define BITS48 0xFFFFFFFFFFFF
#define BITS32 0xFFFFFFFF
#define BITS3  0b111l

//      s=sign, e=exponent, m=mantissa
//      BITS_FLOAT_HEADER   seeeeeeeeeeem
#define BITS_FLOAT_HEADER 0b0111111111111l
#define BITS_UNSIGNED_INT 0b111l
#define BITS_SIGNED_INT   0b110l
#define BITS_SPECIAL      0b101l
#define BITS_UNUSED2      0b100l
#define BITS_UNUSED3      0b011l
#define BITS_UNUSED4      0b010l
#define BITS_STR_PTR      0b001l
#define BITS_POINTER      0b000l

#define BITS_SPECIAL_NIL   0b01
#define BITS_SPECIAL_TRUE  0b10
#define BITS_SPECIAL_FALSE 0b11
#define TYPE(type) (BITS_FLOAT_HEADER << 51 | (type) << 48)
#define SPECIAL(bits) (TYPE(BITS_SPECIAL) | bits)
#define IS_TYPE(data, type) (((data) & TYPE(BITS3)) == (TYPE(type)))


jlisp_type jlisp_nil();
bool is_jlisp_nil(jlisp_type data);

jlisp_type jlisp_true();
bool is_jlisp_true(jlisp_type data);

jlisp_type jlisp_false();
bool is_jlisp_false(jlisp_type data);

jlisp_type jlisp_uint48(uint64_t data);
bool is_jlisp_uint48(jlisp_type data);

jlisp_type jlisp_int32(int32_t data);
bool is_jlisp_int32(jlisp_type data);

jlisp_type jlisp_pointer(void* data);
bool is_jlisp_pointer(jlisp_type data);

jlisp_type jlisp_string(char* data);
bool is_jlisp_string(jlisp_type data);


char* jlisp_typeof(jlisp_type t);

char* jlisp_value_to_string(jlisp_type t);
