#!/bin/sh

# Host build for SQLite3

HOST=$(pwd)
OUT=$HOST/out

cd ..
SQLITE3_SRC=$(pwd)/sqlite3/src/main/jni/sqlite/sqlite3.c
SQLITE3_INCLUDE=$(pwd)/sqlite3/src/main/jni/sqlite/
cd $HOST

if [ ! -d $OUT ]; then
    mkdir $OUT
fi

gcc -Os -v \
    -I$SQLITE3_INCLUDE \
    -DSQLITE_THREADSAFE=0 \
    -DSQLITE_ENABLE_FTS3 \
    -DSQLITE_ENABLE_FTS4 \
    -DSQLITE_ENABLE_FTS5 \
    -DSQLITE_ENABLE_JSON1 \
    -DSQLITE_ENABLE_RTREE \
    -DSQLITE_ENABLE_EXPLAIN_COMMNETS \
    -DSQLITE_ENABLE_ICU \
    -DHAVE_READLINE \
    -DSQLITE_ENABLE_LOAD_EXTENSION=1 \
    $HOST/shell.c $SQLITE3_SRC \
    -licui18n -licuio -licutu -licuuc -licudata \
    -ldl -lreadline -lncurses -lm -lstdc++ \
    -o $OUT/sqlite3

# Build for extensions

cd ../builtin_extensions
EXTENSIONS_SRC_DIR=$(pwd)/jni
cd $HOST

# Build for offsets_rank
gcc -v -shared -fpic \
    -I$SQLITE3_INCLUDE \
    -I$EXTENSIONS_SRC_DIR \
    $EXTENSIONS_SRC_DIR/offsets_rank.c \
    -o $OUT/liboffsets_rank.so

# Build for okapi_bm25
gcc -v -shared -fpic \
    -I$SQLITE3_INCLUDE \
    -I$EXTENSIONS_SRC_DIR \
    $EXTENSIONS_SRC_DIR/okapi_bm25.c \
    -o $OUT/libokapi_bm25.so

# Build for spellfix
gcc -v -shared -fpic \
    -I$SQLITE3_INCLUDE \
    -I$EXTENSIONS_SRC_DIR \
    $EXTENSIONS_SRC_DIR/spellfix1.c \
    -o $OUT/libspellfix.so
