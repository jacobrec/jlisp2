#include <stdio.h>

#include "symboltable.h"
#include "bin/tokens.c"
#include "vm.h"

int main() {
    if(NULL != 0) {
        exit(1);
    }
    enum token tok;
    tok = STRING1;

    printf("Hello, World: %s\n", token_to_string(tok));

    printf("%d %d %d\n", intern_symbol("hi"), intern_symbol("hello"), intern_symbol("hi"));

}
