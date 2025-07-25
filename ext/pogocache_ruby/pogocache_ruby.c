#include <ruby.h>
#include "pogocache.h"

// Ruby module and class definitions
static VALUE mPogocache;
static VALUE cExtension;
static VALUE ePogoError;

// Data type for wrapping pogocache struct
typedef struct {
    struct pogocache *cache;
} pogocache_wrapper_t;

// Cleanup function for garbage collection
static void pogocache_free_wrapper(void *ptr) {
    pogocache_wrapper_t *wrapper = (pogocache_wrapper_t*)ptr;
    if (wrapper && wrapper->cache) {
        pogocache_free(wrapper->cache);
        wrapper->cache = NULL;
    }
    free(wrapper);
}

static const rb_data_type_t pogocache_data_type = {
    "Pogocache",
    {0, pogocache_free_wrapper, 0},
    0, 0,
    RUBY_TYPED_FREE_IMMEDIATELY
};

// Helper function to get pogocache from Ruby object
static pogocache_wrapper_t* get_pogocache_wrapper(VALUE self) {
    pogocache_wrapper_t *wrapper;
    TypedData_Get_Struct(self, pogocache_wrapper_t, &pogocache_data_type, wrapper);
    if (!wrapper->cache) {
        rb_raise(ePogoError, "Pogocache instance has been freed");
    }
    return wrapper;
}

// Helper function to convert Ruby hash to pogocache_opts
static struct pogocache_opts* hash_to_opts(VALUE opts_hash) {
    static struct pogocache_opts opts;
    memset(&opts, 0, sizeof(opts));
    
    // Set defaults
    opts.nshards = 65536;
    opts.loadfactor = 75;
    
    if (NIL_P(opts_hash)) {
        return &opts;
    }
    
    Check_Type(opts_hash, T_HASH);
    
    VALUE val;
    
    // usecas
    val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("usecas")));
    if (!NIL_P(val)) opts.usecas = RTEST(val);
    
    // nosixpack
    val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("nosixpack")));
    if (!NIL_P(val)) opts.nosixpack = RTEST(val);
    
    // noevict
    val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("noevict")));
    if (!NIL_P(val)) opts.noevict = RTEST(val);
    
    // allowshrink
    val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("allowshrink")));
    if (!NIL_P(val)) opts.allowshrink = RTEST(val);
    
    // usethreadbatch
    val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("usethreadbatch")));
    if (!NIL_P(val)) opts.usethreadbatch = RTEST(val);
    
    // nshards
    val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("nshards")));
    if (!NIL_P(val)) opts.nshards = NUM2INT(val);
    
    // loadfactor
    val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("loadfactor")));
    if (!NIL_P(val)) opts.loadfactor = NUM2INT(val);
    
    // seed
    val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("seed")));
    if (!NIL_P(val)) opts.seed = NUM2ULL(val);
    
    return &opts;
}

// Initialize a new Pogocache instance
// Pogocache.new(opts = {})
static VALUE pogocache_initialize(int argc, VALUE *argv, VALUE self) {
    VALUE opts_hash;
    rb_scan_args(argc, argv, "01", &opts_hash);
    
    struct pogocache_opts *opts = hash_to_opts(opts_hash);
    struct pogocache *cache = pogocache_new(opts);
    
    if (!cache) {
        rb_raise(ePogoError, "Failed to create pogocache instance");
    }
    
    pogocache_wrapper_t *wrapper = malloc(sizeof(pogocache_wrapper_t));
    wrapper->cache = cache;
    
    DATA_PTR(self) = wrapper;
    return self;
}

// Store a key-value pair
// extension.store(key, value, opts = {})
static VALUE pogocache_store_rb(int argc, VALUE *argv, VALUE self) {
    VALUE key, value, opts_hash;
    rb_scan_args(argc, argv, "21", &key, &value, &opts_hash);
    
    pogocache_wrapper_t *wrapper = get_pogocache_wrapper(self);
    
    // Convert Ruby strings to C strings
    Check_Type(key, T_STRING);
    Check_Type(value, T_STRING);
    
    const char *key_ptr = RSTRING_PTR(key);
    size_t key_len = RSTRING_LEN(key);
    const char *value_ptr = RSTRING_PTR(value);
    size_t value_len = RSTRING_LEN(value);
    
    // Parse options
    struct pogocache_store_opts opts;
    memset(&opts, 0, sizeof(opts));
    
    if (!NIL_P(opts_hash)) {
        Check_Type(opts_hash, T_HASH);
        
        VALUE val;
        
        // ttl
        val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("ttl")));
        if (!NIL_P(val)) opts.ttl = NUM2LL(val);
        
        // expires
        val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("expires")));
        if (!NIL_P(val)) opts.expires = NUM2LL(val);
        
        // flags
        val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("flags")));
        if (!NIL_P(val)) opts.flags = NUM2UINT(val);
        
        // cas
        val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("cas")));
        if (!NIL_P(val)) opts.cas = NUM2ULL(val);
        
        // nx (only set if not exists)
        val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("nx")));
        if (!NIL_P(val)) opts.nx = RTEST(val);
        
        // xx (only set if exists)
        val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("xx")));
        if (!NIL_P(val)) opts.xx = RTEST(val);
        
        // keepttl
        val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("keepttl")));
        if (!NIL_P(val)) opts.keepttl = RTEST(val);
        
        // casop
        val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("casop")));
        if (!NIL_P(val)) opts.casop = RTEST(val);
    }
    
    int result = pogocache_store(wrapper->cache, key_ptr, key_len, value_ptr, value_len, &opts);
    return INT2NUM(result);
}

// Load callback data structure
typedef struct {
    VALUE result_hash;
    bool found;
} load_callback_data_t;

// Callback function for pogocache_load
static void load_entry_callback(int shard, int64_t time, const void *key, size_t keylen,
                               const void *value, size_t valuelen, int64_t expires, 
                               uint32_t flags, uint64_t cas, struct pogocache_update **update, 
                               void *udata) {
    load_callback_data_t *data = (load_callback_data_t*)udata;
    
    data->result_hash = rb_hash_new();
    data->found = true;
    
    rb_hash_aset(data->result_hash, ID2SYM(rb_intern("key")), 
                 rb_str_new((const char*)key, keylen));
    rb_hash_aset(data->result_hash, ID2SYM(rb_intern("value")), 
                 rb_str_new((const char*)value, valuelen));
    rb_hash_aset(data->result_hash, ID2SYM(rb_intern("expires")), LL2NUM(expires));
    rb_hash_aset(data->result_hash, ID2SYM(rb_intern("flags")), UINT2NUM(flags));
    rb_hash_aset(data->result_hash, ID2SYM(rb_intern("cas")), ULL2NUM(cas));
    rb_hash_aset(data->result_hash, ID2SYM(rb_intern("shard")), INT2NUM(shard));
    rb_hash_aset(data->result_hash, ID2SYM(rb_intern("time")), LL2NUM(time));
}

// Load a value by key
// extension.load(key, opts = {})
static VALUE pogocache_load_rb(int argc, VALUE *argv, VALUE self) {
    VALUE key, opts_hash;
    rb_scan_args(argc, argv, "11", &key, &opts_hash);
    
    pogocache_wrapper_t *wrapper = get_pogocache_wrapper(self);
    
    Check_Type(key, T_STRING);
    const char *key_ptr = RSTRING_PTR(key);
    size_t key_len = RSTRING_LEN(key);
    
    struct pogocache_load_opts opts;
    memset(&opts, 0, sizeof(opts));
    
    load_callback_data_t callback_data;
    callback_data.result_hash = Qnil;
    callback_data.found = false;
    
    opts.entry = load_entry_callback;
    opts.udata = &callback_data;
    
    if (!NIL_P(opts_hash)) {
        Check_Type(opts_hash, T_HASH);
        
        VALUE val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("notouch")));
        if (!NIL_P(val)) opts.notouch = RTEST(val);
    }
    
    int result = pogocache_load(wrapper->cache, key_ptr, key_len, &opts);
    if (result != POGOCACHE_FOUND) {
        return Qnil;
    }
    
    if (callback_data.found) {
        return callback_data.result_hash;
    } else {
        return Qnil;
    }
}

// Delete a key
// extension.delete(key, opts = {})
static VALUE pogocache_delete_rb(int argc, VALUE *argv, VALUE self) {
    VALUE key, opts_hash;
    rb_scan_args(argc, argv, "11", &key, &opts_hash);
    
    pogocache_wrapper_t *wrapper = get_pogocache_wrapper(self);
    
    Check_Type(key, T_STRING);
    const char *key_ptr = RSTRING_PTR(key);
    size_t key_len = RSTRING_LEN(key);
    
    struct pogocache_delete_opts opts;
    memset(&opts, 0, sizeof(opts));
    
    int result = pogocache_delete(wrapper->cache, key_ptr, key_len, &opts);
    return INT2NUM(result);
}

// Get cache count
// extension.count(opts = {})
static VALUE pogocache_count_rb(int argc, VALUE *argv, VALUE self) {
    VALUE opts_hash;
    rb_scan_args(argc, argv, "01", &opts_hash);
    
    pogocache_wrapper_t *wrapper = get_pogocache_wrapper(self);
    
    struct pogocache_count_opts opts;
    memset(&opts, 0, sizeof(opts));
    
    if (!NIL_P(opts_hash)) {
        Check_Type(opts_hash, T_HASH);
        
        VALUE val;
        val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("oneshard")));
        if (!NIL_P(val)) opts.oneshard = RTEST(val);
        
        val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("oneshardidx")));
        if (!NIL_P(val)) opts.oneshardidx = NUM2INT(val);
    }
    
    size_t count = pogocache_count(wrapper->cache, &opts);
    return SIZET2NUM(count);
}

// Get cache memory size
// extension.size(opts = {})
static VALUE pogocache_size_rb(int argc, VALUE *argv, VALUE self) {
    VALUE opts_hash;
    rb_scan_args(argc, argv, "01", &opts_hash);
    
    pogocache_wrapper_t *wrapper = get_pogocache_wrapper(self);
    
    struct pogocache_size_opts opts;
    memset(&opts, 0, sizeof(opts));
    
    if (!NIL_P(opts_hash)) {
        Check_Type(opts_hash, T_HASH);
        
        VALUE val;
        val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("oneshard")));
        if (!NIL_P(val)) opts.oneshard = RTEST(val);
        
        val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("oneshardidx")));
        if (!NIL_P(val)) opts.oneshardidx = NUM2INT(val);
        
        val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("entriesonly")));
        if (!NIL_P(val)) opts.entriesonly = RTEST(val);
    }
    
    size_t size = pogocache_size(wrapper->cache, &opts);
    return SIZET2NUM(size);
}

// Clear the cache
// extension.clear(opts = {})
static VALUE pogocache_clear_rb(int argc, VALUE *argv, VALUE self) {
    VALUE opts_hash;
    rb_scan_args(argc, argv, "01", &opts_hash);
    
    pogocache_wrapper_t *wrapper = get_pogocache_wrapper(self);
    
    struct pogocache_clear_opts opts;
    memset(&opts, 0, sizeof(opts));
    
    if (!NIL_P(opts_hash)) {
        Check_Type(opts_hash, T_HASH);
        
        VALUE val;
        val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("oneshard")));
        if (!NIL_P(val)) opts.oneshard = RTEST(val);
        
        val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("oneshardidx")));
        if (!NIL_P(val)) opts.oneshardidx = NUM2INT(val);
    }
    
    pogocache_clear(wrapper->cache, &opts);
    return Qnil;
}

// Sweep expired entries
// extension.sweep(opts = {})
static VALUE pogocache_sweep_rb(int argc, VALUE *argv, VALUE self) {
    VALUE opts_hash;
    rb_scan_args(argc, argv, "01", &opts_hash);
    
    pogocache_wrapper_t *wrapper = get_pogocache_wrapper(self);
    
    struct pogocache_sweep_opts opts;
    memset(&opts, 0, sizeof(opts));
    
    if (!NIL_P(opts_hash)) {
        Check_Type(opts_hash, T_HASH);
        
        VALUE val;
        val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("oneshard")));
        if (!NIL_P(val)) opts.oneshard = RTEST(val);
        
        val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("oneshardidx")));
        if (!NIL_P(val)) opts.oneshardidx = NUM2INT(val);
    }
    
    size_t swept = 0, kept = 0;
    pogocache_sweep(wrapper->cache, &swept, &kept, &opts);
    
    VALUE result = rb_hash_new();
    rb_hash_aset(result, ID2SYM(rb_intern("swept")), SIZET2NUM(swept));
    rb_hash_aset(result, ID2SYM(rb_intern("kept")), SIZET2NUM(kept));
    
    return result;
}

// Iterator callback data
typedef struct {
    VALUE result_array;
    VALUE proc;
} iter_callback_data_t;

// Callback function for iteration
static int iter_entry_callback(int shard, int64_t time, const void *key, size_t keylen,
                              const void *value, size_t valuelen, int64_t expires, 
                              uint32_t flags, uint64_t cas, void *udata) {
    iter_callback_data_t *data = (iter_callback_data_t*)udata;
    
    VALUE entry_hash = rb_hash_new();
    rb_hash_aset(entry_hash, ID2SYM(rb_intern("key")), 
                 rb_str_new((const char*)key, keylen));
    rb_hash_aset(entry_hash, ID2SYM(rb_intern("value")), 
                 rb_str_new((const char*)value, valuelen));
    rb_hash_aset(entry_hash, ID2SYM(rb_intern("expires")), LL2NUM(expires));
    rb_hash_aset(entry_hash, ID2SYM(rb_intern("flags")), UINT2NUM(flags));
    rb_hash_aset(entry_hash, ID2SYM(rb_intern("cas")), ULL2NUM(cas));
    rb_hash_aset(entry_hash, ID2SYM(rb_intern("shard")), INT2NUM(shard));
    rb_hash_aset(entry_hash, ID2SYM(rb_intern("time")), LL2NUM(time));
    
    if (!NIL_P(data->proc)) {
        VALUE result = rb_funcall(data->proc, rb_intern("call"), 1, entry_hash);
        return NUM2INT(result);
    } else {
        rb_ary_push(data->result_array, entry_hash);
        return POGOCACHE_ITER_CONTINUE;
    }
}

// Iterate over cache entries
// extension.each(opts = {}) { |entry| ... }
// extension.each(opts = {}) # returns array
static VALUE pogocache_each_rb(int argc, VALUE *argv, VALUE self) {
    VALUE opts_hash, proc;
    rb_scan_args(argc, argv, "01&", &opts_hash, &proc);
    
    pogocache_wrapper_t *wrapper = get_pogocache_wrapper(self);
    
    struct pogocache_iter_opts opts;
    memset(&opts, 0, sizeof(opts));
    
    iter_callback_data_t callback_data;
    callback_data.result_array = rb_ary_new();
    callback_data.proc = proc;
    
    opts.entry = iter_entry_callback;
    opts.udata = &callback_data;
    
    if (!NIL_P(opts_hash)) {
        Check_Type(opts_hash, T_HASH);
        
        VALUE val;
        val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("oneshard")));
        if (!NIL_P(val)) opts.oneshard = RTEST(val);
        
        val = rb_hash_aref(opts_hash, ID2SYM(rb_intern("oneshardidx")));
        if (!NIL_P(val)) opts.oneshardidx = NUM2INT(val);
    }
    
    pogocache_iter(wrapper->cache, &opts);
    
    if (!NIL_P(proc)) {
        return self;
    } else {
        return callback_data.result_array;
    }
}

// Get number of shards
// extension.nshards
static VALUE pogocache_nshards_rb(VALUE self) {
    pogocache_wrapper_t *wrapper = get_pogocache_wrapper(self);
    int nshards = pogocache_nshards(wrapper->cache);
    return INT2NUM(nshards);
}

// Get current time
// Pogocache.now
static VALUE pogocache_now_rb(VALUE self) {
    int64_t now = pogocache_now();
    return LL2NUM(now);
}
static VALUE pogocache_alloc(VALUE klass) {
    pogocache_wrapper_t *wrapper = malloc(sizeof(pogocache_wrapper_t));
    wrapper->cache = NULL;
    return TypedData_Wrap_Struct(klass, &pogocache_data_type, wrapper);
}

// Extension initialization
void Init_pogocache_ruby(void) {
    // Define module
    mPogocache = rb_define_module("Pogocache");
    
    // Define Cache class
    cExtension = rb_define_class_under(mPogocache, "Extension", rb_cObject);
    rb_define_alloc_func(cExtension, pogocache_alloc);
    
    // Define exception class
    ePogoError = rb_define_class_under(mPogocache, "Error", rb_eStandardError);
    
    // Instance methods
    rb_define_method(cExtension, "initialize", pogocache_initialize, -1);
    rb_define_method(cExtension, "store", pogocache_store_rb, -1);
    rb_define_method(cExtension, "load", pogocache_load_rb, -1);
    rb_define_method(cExtension, "delete", pogocache_delete_rb, -1);
    rb_define_method(cExtension, "count", pogocache_count_rb, -1);
    rb_define_method(cExtension, "size", pogocache_size_rb, -1);
    rb_define_method(cExtension, "clear", pogocache_clear_rb, -1);
    rb_define_method(cExtension, "sweep", pogocache_sweep_rb, -1);
    rb_define_method(cExtension, "each", pogocache_each_rb, -1);
    rb_define_method(cExtension, "nshards", pogocache_nshards_rb, 0);
    
    // Convenience aliases
    rb_define_alias(cExtension, "[]", "load");
    rb_define_alias(cExtension, "[]=", "store");
    rb_define_alias(cExtension, "length", "count");
    
    // Module methods
    rb_define_module_function(mPogocache, "now", pogocache_now_rb, 0);
    
    // Constants
    rb_define_const(mPogocache, "INSERTED", INT2NUM(POGOCACHE_INSERTED));
    rb_define_const(mPogocache, "REPLACED", INT2NUM(POGOCACHE_REPLACED));
    rb_define_const(mPogocache, "FOUND", INT2NUM(POGOCACHE_FOUND));
    rb_define_const(mPogocache, "NOTFOUND", INT2NUM(POGOCACHE_NOTFOUND));
    rb_define_const(mPogocache, "DELETED", INT2NUM(POGOCACHE_DELETED));
    rb_define_const(mPogocache, "FINISHED", INT2NUM(POGOCACHE_FINISHED));
    rb_define_const(mPogocache, "CANCELED", INT2NUM(POGOCACHE_CANCELED));
    rb_define_const(mPogocache, "NOMEM", INT2NUM(POGOCACHE_NOMEM));
    
    // Time constants
    rb_define_const(mPogocache, "NANOSECOND", LL2NUM(POGOCACHE_NANOSECOND));
    rb_define_const(mPogocache, "MICROSECOND", LL2NUM(POGOCACHE_MICROSECOND));
    rb_define_const(mPogocache, "MILLISECOND", LL2NUM(POGOCACHE_MILLISECOND));
    rb_define_const(mPogocache, "SECOND", LL2NUM(POGOCACHE_SECOND));
    rb_define_const(mPogocache, "MINUTE", LL2NUM(POGOCACHE_MINUTE));
    rb_define_const(mPogocache, "HOUR", LL2NUM(POGOCACHE_HOUR));
    
    // Iterator constants
    rb_define_const(mPogocache, "ITER_CONTINUE", INT2NUM(POGOCACHE_ITER_CONTINUE));
    rb_define_const(mPogocache, "ITER_STOP", INT2NUM(POGOCACHE_ITER_STOP));
    rb_define_const(mPogocache, "ITER_DELETE", INT2NUM(POGOCACHE_ITER_DELETE));
    
    // Eviction reason constants
    rb_define_const(mPogocache, "REASON_EXPIRED", INT2NUM(POGOCACHE_REASON_EXPIRED));
    rb_define_const(mPogocache, "REASON_LOWMEM", INT2NUM(POGOCACHE_REASON_LOWMEM));
    rb_define_const(mPogocache, "REASON_CLEARED", INT2NUM(POGOCACHE_REASON_CLEARED));
}
