#pragma once

struct hash_node {
    char* key;
    uint32_t value;
    uint32_t probe;
};
struct insert_table {
    struct hash_node* buckets;
    int bucket_count;
    int max_probe_count; // also happens to be how many bits are needed for all locations
};

// hashtable with robinhood hashing, linear probing with probelimit,
// power of 2 slots, and fibinacci hash placement
struct insert_table* insert_table_init();
uint32_t insert_table_add(struct insert_table* table, char* key, uint32_t value);
uint32_t insert_table_lookup(struct insert_table* table, char* key); // 0 means it's not in the table
void insert_table_grow(struct insert_table* table);
struct hash_node insert_table_swap(struct insert_table* table, uint64_t loc, struct hash_node item);
