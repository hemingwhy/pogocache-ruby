require "mkmf"

# This should find ruby.h automatically
have_library("pthread")
create_makefile("ext/pogocache")
