
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

char g_buffer[BUFFER_SIZE];

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
    // return g_buffer;
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

void* pogocache_custom_sweep(struct pogocache *cache) {
    struct pogocache_sweep_opts opts = {};
    size_t swept;
    size_t kept;
    pogocache_sweep(cache,  &swept, &kept, &opts);
    size_t *result = malloc(2*sizeof(size_t));
    result[0] = swept;
    result[1] = kept;
    return result;
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
    size_t next_offset;
    char** buffer;
};

int keys_callback(int shard, int64_t time, const void *key, size_t keylen,
    const void *value, size_t valuelen, int64_t expires, uint32_t flags,
    uint64_t cas, void *udata) {
    struct iter_buffer *ibuf = udata;
    ibuf->buffer[ibuf->next_offset] = malloc(sizeof(char) * keylen + sizeof(size_t));
    memcpy(ibuf->buffer[ibuf->next_offset], &keylen, sizeof(size_t));
    memcpy(ibuf->buffer[ibuf->next_offset] + sizeof(size_t), key, keylen);
    ibuf->next_offset++;
}

char** pogocache_custom_keys(struct pogocache *cache) {
    size_t keycount = pogocache_custom_count(cache);
    char **buffer;
    buffer = malloc(keycount * sizeof(size_t));
    struct iter_buffer ibuf = { .next_offset = 0, .buffer =  buffer };
    struct pogocache_iter_opts iopts = {.entry = keys_callback, .udata = &ibuf};
    pogocache_iter(cache, &iopts);
    return buffer;
}

void pogocache_custom_clear(struct pogocache *cache) {
    struct pogocache_clear_opts copts = {};
    pogocache_clear(cache, &copts);
}

struct pogocache* pogocache_custom_begin(struct pogocache *cache) {
    return pogocache_begin(cache);
}

void pogocache_custom_end(struct pogocache *batch) {
    pogocache_end(batch);    
}

void Init_pogocache_ruby(void) {
}
