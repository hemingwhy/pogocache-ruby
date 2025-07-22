
// prog.c
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include "pogocache.h"

static void load_callback(int shard, int64_t time, const void *key,
    size_t keylen, const void *value, size_t valuelen, int64_t expires, 
    uint32_t flags, uint64_t cas, struct pogocache_update **update, 
    void *udata)
{
    sprintf(udata,"%.*s", (int)valuelen, (char *)value);
}

void *load_buffer;

void init_load_buffer(size_t size) {
  load_buffer = malloc(size);
}

void* pogo_load(struct pogocache *cache, const void *key, size_t keylen)
{
    struct pogocache_load_opts lopts = { .entry = load_callback, .udata = load_buffer };
    if(pogocache_load(cache, key, keylen, &lopts) == POGOCACHE_FOUND) {
        return load_buffer;
    } else {
        return NULL;
    }
}

int main(void) {
    // Create a Pogocache instance
    struct pogocache *cache = pogocache_new(0);

    // Store some values
    pogocache_store(cache, "user:1391:name", 14, "Tom", 3, 0);
    pogocache_store(cache, "user:1391:last", 14, "Anderson", 8, 0);
    pogocache_store(cache, "user:1391:age", 13, "37", 2, 0);

    void *result = malloc(10101010);
    
    // Read the values back
    struct pogocache_load_opts lopts = { .entry = load_callback, .udata = result };
    pogocache_load(cache, "user:1391:name", 14, &lopts);
    printf("result %s\n", (char *)result);
    pogocache_load(cache, "user:1391:last", 14, &lopts);
    printf("result %s\n", (char *)result);
    pogocache_load(cache, "user:1391:age", 13, &lopts);
    
    printf("result %s\n", (char *)result);
    return 0;
}
// Tom
// Anderson
// 37
