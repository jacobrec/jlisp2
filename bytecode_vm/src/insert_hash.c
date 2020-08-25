#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>

#include "insert_hash.h"

#define FIB_CONST 11400714819323198485llu
uint64_t fib_hash(uint64_t num, int bits_used) {
    return (FIB_CONST * num) >> 64 - bits_used;
}
// TODO: replace with better hash
// string must be null terminated
uint64_t string_hash(char* string) {
    uint64_t hash = 5;
    for(int i = 0; i < strlen(string); i++) {
        hash = hash*31 + string[i]*(i+1);
    }
    return hash;
}




struct insert_table* insert_table_init() {
    struct insert_table* table = malloc(sizeof(struct insert_table));
    table->bucket_count = 64;
    table->max_probe_count = log2(table->bucket_count);
    table->buckets = calloc(table->bucket_count + table->max_probe_count, sizeof(struct hash_node));
}

uint32_t insert_table_add(struct insert_table* table, char* key, uint32_t value) {
    struct hash_node item;
    item.key = key;
    item.value = value;

    uint64_t desired_loc = fib_hash(string_hash(key), table->max_probe_count);
    for(item.probe = 0; item.probe < table->max_probe_count; item.probe++) {
        if (table->buckets[desired_loc + item.probe].key == NULL) {
            table->buckets[desired_loc + item.probe] = item;
            return item.value;
        } else if (table->buckets[desired_loc + item.probe].probe > item.probe) {
            item = insert_table_swap(table, desired_loc + item.probe, item);
        }
    }
    insert_table_grow(table);
    insert_table_add(table, key, value);
}

uint32_t insert_table_lookup(struct insert_table* table, char* key) {
    uint64_t desired_loc = fib_hash(string_hash(key), table->max_probe_count);
    for(int i = 0; i < table->max_probe_count; i++) {
        if (table->buckets[desired_loc + i].key == NULL){
            return 0;
        } else if(strcmp(key, table->buckets[desired_loc + i].key) == 0) {
            return table->buckets[desired_loc + i].value;
        }
    }
    return 0;
}

struct hash_node insert_table_swap(struct insert_table* table, uint64_t loc, struct hash_node item) {
    struct hash_node new = table->buckets[loc];
    table->buckets[loc] = item;
    return new;
}

void insert_table_grow(struct insert_table* table) {
    table->bucket_count *= 2;
    table->max_probe_count = log2(table->bucket_count);
    table->buckets = realloc(table->buckets, (table->bucket_count + table->max_probe_count) * sizeof(struct hash_node));

    int len = table->bucket_count / 2;
    memset(table->buckets + len, 0, len); // set new memory to 0
}
