#include <stddef.h>
#include <stdlib.h>
#include "vm.h"

void init_vm(struct VM* vm) {
    vm->data = NULL;
    vm->data_size = 0;
    vm->ip = 0;
}
void run(struct VM* vm, char* data, int length) {
    // add new data
    vm->data_size += length;
    vm->data = realloc(vm->data, vm->data_size);

    // actually run
}
