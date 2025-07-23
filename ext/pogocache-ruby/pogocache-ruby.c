
// prog.c
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include "pogocache.h"

#include <ruby.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>

#define BUFFER_SIZE 4096*1024

static pthread_key_t buffer_key;
static pthread_once_t key_once = PTHREAD_ONCE_INIT;

static void buffer_destructor(void *buffer) {
    if (buffer) {
        free(buffer);
    }
}

static void make_key(void) {
    pthread_key_create(&buffer_key, buffer_destructor);
}

static char* get_thread_buffer(void) {
    pthread_once(&key_once, make_key);
    
    char *buffer = pthread_getspecific(buffer_key);
    if (!buffer) {
        buffer = malloc(BUFFER_SIZE);
        if (!buffer) {
            rb_raise(rb_eNoMemError, "Failed to allocate thread buffer");
        }
        pthread_setspecific(buffer_key, buffer);
    }
    return buffer;
}

static void load_callback(int shard, int64_t time, const void *key,
    size_t keylen, const void *value, size_t valuelen, int64_t expires, 
    uint32_t flags, uint64_t cas, struct pogocache_update **update, 
    void *udata) {
    memcpy(udata, &valuelen, sizeof(size_t));
    memcpy(udata+8, value, valuelen+sizeof(size_t));
}

void* pogocache_custom_load(struct pogocache *cache, const void *key, size_t keylen) {
    void *load_buffer = get_thread_buffer();
    struct pogocache_load_opts lopts = { .entry = load_callback, .udata = load_buffer };
    if(pogocache_load(cache, key, keylen, &lopts) == POGOCACHE_FOUND) {
        return load_buffer;
    } else {
        return NULL;
    }
}

static bool delete_callback(int shard, int64_t time, const void *key, size_t keylen,
        const void *value, size_t valuelen, int64_t expires, uint32_t flags,
        uint64_t cas, void *udata) {
    return true;
}

int pogocache_custom_delete(struct pogocache *cache, const void *key, size_t keylen) {
    struct pogocache_delete_opts dopts = { .entry = delete_callback };
    return pogocache_delete(cache, key, keylen, &dopts);
}

int pogocache_custom_store(struct pogocache *cache, const void *key, size_t keylen, const void *value, size_t vallen, int64_t ttl) {
    struct pogocache_store_opts sopts = { .ttl = ttl };
    return pogocache_store(cache, key, keylen, value, vallen, &sopts);
}

int pogocache_custom_count(struct pogocache *cache) {
    struct pogocache_count_opts copts = {};
    return pogocache_count(cache, &copts);
}

int pogocache_custom_size(struct pogocache *cache) {
    struct pogocache_size_opts copts = {.entriesonly = true};
    return pogocache_size(cache, &copts);
}

uint64_t pogocache_custom_total(struct pogocache *cache) {
    struct pogocache_total_opts opts = {};
    return pogocache_total(cache, &opts);
}

struct iter_buffer {
    char* next;
    char** buffer;
};

int keys_callback(int shard, int64_t time, const void *key, size_t keylen,
    const void *value, size_t valuelen, int64_t expires, uint32_t flags,
    uint64_t cas, void *udata) {
    struct iter_buffer *ibuf = udata;
    memcpy(udata, key, keylen);
    ibuf->next = ibuf->next + (keylen + 1) * sizeof(char);
}

char** pogocache_custom_keys(struct pogocache *cache) {
    size_t keycount = pogocache_custom_size(cache);
    printf("%zu", keycount);
    char **buffer;
    buffer = malloc(keycount * sizeof(size_t));
    struct iter_buffer ibuf = {.next = NULL, .buffer = buffer};
    struct pogocache_iter_opts iopts = {.entry = keys_callback, .udata = &buffer};
    for(int i = 0; i < keycount; i++) {
        // printf("%s", *ibuf.buffer);
    }

    return buffer;
}

void Init_pogocache_ruby(void) {
    printf("loading pogo");
}
