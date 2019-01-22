LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)


# If using SEE, uncomment the following:
# LOCAL_CFLAGS += -DSQLITE_HAS_CODEC -fvisibility=default


# Enable SQLite extensions.
LOCAL_CFLAGS += -DSQLITE_ENABLE_FTS5
LOCAL_CFLAGS += -DSQLITE_ENABLE_RTREE
LOCAL_CFLAGS += -DSQLITE_ENABLE_JSON1
LOCAL_CFLAGS += -DSQLITE_ENABLE_FTS3
LOCAL_CFLAGS += -DSQLITE_ENABLE_FTS4
LOCAL_CFLAGS += -DSQLITE_ENABLE_LOAD_EXTENSION=1
LOCAL_CFLAGS += -DSQLITE_ENABLE_ICU
# LOCAL_CFLAGS += -DU_DISABLE_RENAMING

# This is important - it causes SQLite to use memory for temp files. Since 
# Android has no globally writable temp directory, if this is not defined the
# application throws an exception when it tries to create a temp file.
#
LOCAL_CFLAGS += -DSQLITE_TEMP_STORE=3

LOCAL_CFLAGS += -DHAVE_CONFIG_H -DKHTML_NO_EXCEPTIONS -DGKWQ_NO_JAVA
LOCAL_CFLAGS += -DNO_SUPPORT_JS_BINDING -DQT_NO_WHEELEVENT -DKHTML_NO_XBL
LOCAL_CFLAGS += -U__APPLE__
LOCAL_CFLAGS += -DHAVE_STRCHRNUL=0
LOCAL_CFLAGS += -Wno-unused-parameter -Wno-int-to-pointer-cast
LOCAL_CFLAGS += -Wno-maybe-uninitialized -Wno-parentheses
LOCAL_CPPFLAGS += -Wno-conversion-null


ifeq ($(TARGET_ARCH), arm)
    LOCAL_CFLAGS += -DPACKED="__attribute__ ((packed))"
else
    LOCAL_CFLAGS += -DPACKED=""
endif

LOCAL_SRC_FILES:=                         \
    android_database_SQLiteCommon.cpp     \
    android_database_SQLiteConnection.cpp \
    android_database_SQLiteGlobal.cpp     \
    android_database_SQLiteDebug.cpp      \
    JNIHelp.cpp JniConstants.cpp

LOCAL_SRC_FILES += sqlite3.c

LOCAL_C_INCLUDES += $(LOCAL_PATH) $(LOCAL_PATH)/nativehelper/

$(info LOCAL_C_INCLUDES = $(LOCAL_C_INCLUDES))

LOCAL_MODULE:= libsqliteX
LOCAL_LDLIBS += -ldl -llog

# Local lib
$(info TARGET_ARCH = $(TARGET_ARCH))

ifeq ($(TARGET_ARCH), arm)
    LOCAL_LIB := $(LOCAL_PATH)/icu_lib_armv7
else
    LOCAL_LIB := $(LOCAL_PATH)/icu_lib_arm64
endif


# IMPORTANT -licudata must be placed after -licuuc
LOCAL_LDLIBS += -L$(LOCAL_LIB) -licui18n -licuio -licutu -licuuc -licudata

include $(BUILD_SHARED_LIBRARY)
