LOCAL_PATH := $(call my-dir)

# build okapi bm25
include $(CLEAR_VARS)

LOCAL_CFLAGS := -std=c99 -Os

LOCAL_MODULE := okapi_bm25
LOCAL_SRC_FILES := okapi_bm25.c

include $(BUILD_SHARED_LIBRARY)

# build offsets rank
include $(CLEAR_VARS)

LOCAL_CFLAGS := -std=c99 -Os

LOCAL_MODULE := offsets_rank
LOCAL_SRC_FILES := offsets_rank.c

include $(BUILD_SHARED_LIBRARY)

# build spell fix
include $(CLEAR_VARS)

LOCAL_CFLAGS := -std=c99 -Os

LOCAL_MODULE := spellfix
LOCAL_SRC_FILES := spellfix1.c

include $(BUILD_SHARED_LIBRARY)
