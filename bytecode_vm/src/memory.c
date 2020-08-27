#include <assert.h>
#include <stdint.h>

#include "memory.h"
#include "types.h"

jlisp_type jlisp_allocate() {
    void* p = malloc(sizeof(struct jlisp_cons_cell));
    return jlisp_pointer(p);
}
