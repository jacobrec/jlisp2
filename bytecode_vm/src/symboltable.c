#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>

#include "symboltable.h"

// symbol hashtable (insert only)

struct symboltable* table = NULL;
uint32_t intern_symbol(char* key) {
    if (table == NULL) {
        table = symbol_table_init();
    }
    uint32_t res = symbol_table_lookup(table, key);
    return res ? res : symbol_table_add(table, key);
}

// hashtable with robinhood hashing, linear probing with probelimit,
// power of 2 slots, and fibinacci hash placement
#define FIB_CONST 11400714819323198485llu
uint64_t fib_hash(uint64_t num, int bits_used) {
    return (FIB_CONST * num) >> 64 - bits_used;
}
// string must be null terminated
uint64_t string_hash(char* string) {
    uint64_t hash = 5;
    for(int i = 0; i < strlen(string); i++) {
        hash = hash*31 + string[i]*(i+1);
    }
    return hash;
}
struct hash_node {
    char* key;
    uint32_t value;
    uint32_t probe;
};
struct symboltable {
    struct hash_node* buckets;
    int bucket_count;
    int max_probe_count; // also happens to be how many bits are needed for all locations
};


struct symboltable* symbol_table_init() {
    struct symboltable* table = malloc(sizeof(struct symboltable));
    table->bucket_count = 64;
    table->max_probe_count = log2(table->bucket_count);
    table->buckets = calloc(table->bucket_count + table->max_probe_count, sizeof(struct hash_node));
}


uint32_t next_value = 1;
#define NEXT_VALUE() (next_value++)
uint32_t symbol_table_add(struct symboltable* table, char* key) {
    struct hash_node item;
    item.key = key;
    item.value = NEXT_VALUE();

    uint64_t desired_loc = fib_hash(string_hash(key), table->max_probe_count);
    for(item.probe = 0; item.probe < table->max_probe_count; item.probe++) {
        if (table->buckets[desired_loc + item.probe].key == NULL) {
            table->buckets[desired_loc + item.probe] = item;
            return item.value;
        } else if (table->buckets[desired_loc + item.probe].probe > item.probe) {
            item = symbol_table_swap(table, desired_loc + item.probe, item);
        }
    }
    symbol_table_grow(table);
    symbol_table_add(table, key);
}
#undef NEXT_VALUE

uint32_t symbol_table_lookup(struct symboltable* table, char* key) {
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

struct hash_node symbol_table_swap(struct symboltable* table, uint64_t loc, struct hash_node item) {
    struct hash_node new = table->buckets[loc];
    table->buckets[loc] = item;
    return new;
}

void symbol_table_grow(struct symboltable* table) {
    table->bucket_count *= 2;
    table->max_probe_count = log2(table->bucket_count);
    table->buckets = realloc(table->buckets, (table->bucket_count + table->max_probe_count) * sizeof(struct hash_node));

    int len = table->bucket_count / 2;
    memset(table->buckets + len, 0, len); // set new memory to 0
}
