#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>

#include "symboltable.h"
#include "insert_hash.h"

// symbol hashtable (insert only)

uint32_t next_value = 0;
struct insert_table* table = NULL;
uint32_t intern_symbol(char* key) {
    if (table == NULL) {
        table = insert_table_init();
    }
    uint32_t res = insert_table_lookup(table, key);
    return res ? res : insert_table_add(table, key, ++next_value);
}

