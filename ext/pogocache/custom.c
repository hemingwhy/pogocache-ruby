
// prog.c
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include "pogocache.h"

#include <ruby.h>
#include <pthread.h>
#include <stdlib.h>

#define BUFFER_SIZE 4096

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
    void *udata)
{
    sprintf(udata,"%.*s", (int)valuelen, (char *)value);
}

void* pogo_load(struct pogocache *cache, const void *key, size_t keylen)
{
    void *load_buffer = get_thread_buffer();
    struct pogocache_load_opts lopts = { .entry = load_callback, .udata = load_buffer };
    if(pogocache_load(cache, key, keylen, &lopts) == POGOCACHE_FOUND) {
        return load_buffer;
    } else {
        return NULL;
    }
}

