#pragma once
#include <stdlib.h>
#include <stdint.h>

// public interface
uint32_t intern_symbol(char* key);

// implementation interface
struct symboltable* symbol_table_init();
uint32_t symbol_table_add(struct symboltable* table, char* key);
uint32_t symbol_table_lookup(struct symboltable* table, char* key); // 0 means it's not in the table
void symbol_table_grow(struct symboltable* table);
struct hash_node symbol_table_swap(struct symboltable* table, uint64_t loc, struct hash_node item);
