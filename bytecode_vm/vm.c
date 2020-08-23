#include <stddef.h>
#include "vm.h"

void init_vm(struct VM* vm) {
    vm->data = NULL;
    vm->data_size = 0;
    vm->ip = 0;
}
void run(struct VM* vm, char* data, int length) {
}
