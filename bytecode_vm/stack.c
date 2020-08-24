#include <stdlib.h>
#include "stack.h"

struct stack* stack_init() {
    struct stack* s = calloc(1, sizeof(struct stack)); // calloc zeros out memory
    return s;
}

void resize(struct stack* s) {
    s->data = realloc(s->data, sizeof(jlisp_type) * s->capacity);
}

void growif(struct stack* s) {
    if (s->capacity == s->size) {
        s->capacity = (s->capacity + 1) * 2; // so it cant get stuck at 0
        resize(s);
    }
}

void shrinkif(struct stack* s) {
    if (s->capacity / 3 > s->size) {
        s->capacity /= 2;
        resize(s);
    }
}

void stack_push(struct stack* s, jlisp_type t) {
    // printf("data=%X, size= %d, cap= %d\n", s->data, s->size, s->capacity);
    growif(s);
    s->data[s->size++] = t;
}

jlisp_type stack_pop(struct stack* s) {
    s->size--;
    shrinkif(s);
    return s->data[s->size];
}

jlisp_type stack_popn(struct stack* s, int n) {
    s->size -= n;
    shrinkif(s);
    return s->data[s->size];
}

void stack_free(struct stack* s) {
    free(s->data);
    free(s);
}
