#include <stdio.h>

#include "bin/tokens.c"
#include "vm.h"



int main() {
    enum token tok;
    tok = STRING1;

    printf("Hello, World: %s\n", token_to_string(tok));
}
