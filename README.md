# OpenSSL / CURL for Android
Automatically compile static OpenSSL and CURL library for Android by Github Actions with NDK r24.

Added `-fPIC` to fix linking error.

## Android
`armeabi`、`mips`、`mips64` targets are no longer supported with NDK R17+.
|ABI|API|NDK|
|:-|:-:|:-:|
|armeabi|21|r24|
|armeabi-v7a|21|r24|
|arm64-v8a|21|r24|
|x86|21|r24|
|x86_64|21|r24|

## Usage

### Directory Structure
The release contains a single zip file with the following structure:
```
Output.zip
     .
├── curl
│   ├── arm64-v8a
│   │   ├── include
│   │   └── lib
│   ├── armeabi-v7a
│   │   ├── include
│   │   └── lib
│   ├── x86
│   │   ├── include
│   │   └── lib
│   └── x86_64
│       ├── include
│       └── lib
└── openssl
    ├── arm64-v8a
    │   ├── include
    │   └── lib
    ├── armeabi-v7a
    │   ├── include
    │   └── lib
    ├── x86
    │   ├── include
    │   └── lib
    └── x86_64
        ├── include
        └── lib
```

### Integration with Android.mk

If you extract the ZIP file into your project's `loginUtils` folder, you can include the libraries in your Android.mk file as follows:

```makefile
# ─── Prebuilt: libcurl ──────────────────────────────
include $(CLEAR_VARS)
LOCAL_MODULE            := libcurl
LOCAL_SRC_FILES         := loginUtils/curl/$(TARGET_ARCH_ABI)/lib/libcurl.a
LOCAL_EXPORT_C_INCLUDES := loginUtils/curl/$(TARGET_ARCH_ABI)/include
include $(PREBUILT_STATIC_LIBRARY)


# ─── Prebuilt: libssl ──────────────────────────────
include $(CLEAR_VARS)
LOCAL_MODULE            := libssl
LOCAL_SRC_FILES         := loginUtils/openssl/$(TARGET_ARCH_ABI)/lib/libssl.a
LOCAL_EXPORT_C_INCLUDES := loginUtils/openssl/$(TARGET_ARCH_ABI)/include
include $(PREBUILT_STATIC_LIBRARY)

# ─── Prebuilt: libcrypto ──────────────────────────────
include $(CLEAR_VARS)
LOCAL_MODULE            := libcrypto
LOCAL_SRC_FILES         := loginUtils/openssl/$(TARGET_ARCH_ABI)/lib/libcrypto.a
LOCAL_EXPORT_C_INCLUDES := loginUtils/openssl/$(TARGET_ARCH_ABI)/include
include $(PREBUILT_STATIC_LIBRARY)
```

Then link against these libraries in your module:

```makefile
LOCAL_STATIC_LIBRARIES := \
    libcrypto \
    libssl \
    libcurl
```

### Integration with CMake

For CMake-based projects, add the following to your CMakeLists.txt:

```cmake
# Define the library paths based on the ABI
set(LIBS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/loginUtils)

# Add OpenSSL libraries
add_library(ssl STATIC IMPORTED)
set_target_properties(ssl PROPERTIES IMPORTED_LOCATION
    ${LIBS_DIR}/openssl/${ANDROID_ABI}/lib/libssl.a)

add_library(crypto STATIC IMPORTED)
set_target_properties(crypto PROPERTIES IMPORTED_LOCATION
    ${LIBS_DIR}/openssl/${ANDROID_ABI}/lib/libcrypto.a)

# Add cURL library
add_library(curl STATIC IMPORTED)
set_target_properties(curl PROPERTIES IMPORTED_LOCATION
    ${LIBS_DIR}/curl/${ANDROID_ABI}/lib/libcurl.a)

# Include headers
include_directories(
    ${LIBS_DIR}/openssl/${ANDROID_ABI}/include
    ${LIBS_DIR}/curl/${ANDROID_ABI}/include
)

# Link the libraries to your target
target_link_libraries(your_target
    curl
    ssl
    crypto
    # other libraries...
)
```

## ChangeLog
| Date      | Content                                                              |
|-----------|----------------------------------------------------------------------|
| NOW EVERY NIGHT UTC 00:00 will autometically update to new version. |
| 2025.04.25 | OpenSSL 3.5.0 + CURL 8.13.0 |
| 2025.04.09 | OpenSSL 3.5.0 |
| 2025.02.12 | OpenSSL 3.4.1 |
| 2024.10.23 | OpenSSL 3.4.0 |
| 2024.09.04 | OpenSSL 3.3.2 |
| 2024.06.05 | OpenSSL 3.3.1 |
| 2024.04.10 | OpenSSL 3.3.0 |
| 2024.02.01 | OpenSSL 3.2.1 |
| 2023.11.24 | OpenSSL 3.2.0 |
| 2023.10.25 | OpenSSL 3.1.4 |
| 2023.09.21 | OpenSSL 3.1.3 |
| 2023.08.03 | OpenSSL 3.1.2 |
| 2023.06.05 | OpenSSL 3.1.1 |
| 2023.03.15 | OpenSSL 3.1.0 |
| 2023.02.09 | OpenSSL 3.0.8 |
| 2022.11.07 | OpenSSL 3.0.7 |
| 2022.07.14 | OpenSSL 3.0.5 |
| 2022.06.23 | OpenSSL 3.0.4 |
| 2022.05.19 | OpenSSL 3.0.3 |
| 2022.03.16 | OpenSSL 3.0.2 |
| 2021.12.24 | OpenSSL 3.0.1 |
| 2021.10.12 | OpenSSL 3.0.0 && `*MIPS` targets are no longer supported|
| 2021.09.08 | OpenSSL 1.1.1l |
| 2021.03.29 | OpenSSL 1.1.1k |
| 2021.02.18 | OpenSSL 1.1.1j |
| 2021.01.20 | OpenSSL 1.1.1i |

```makefile
# ─── Prebuilt: libcurl ──────────────────────────────
include $(CLEAR_VARS)
LOCAL_MODULE            := libcurl
LOCAL_SRC_FILES         := loginUtils/curl/$(TARGET_ARCH_ABI)/lib/libcurl.a
LOCAL_EXPORT_C_INCLUDES := loginUtils/curl/$(TARGET_ARCH_ABI)/include
include $(PREBUILT_STATIC_LIBRARY)


# ─── Prebuilt: libssl ──────────────────────────────
include $(CLEAR_VARS)
LOCAL_MODULE            := libssl
LOCAL_SRC_FILES         := loginUtils/openssl/$(TARGET_ARCH_ABI)/lib/libssl.a
LOCAL_EXPORT_C_INCLUDES := loginUtils/openssl/$(TARGET_ARCH_ABI)/include
include $(PREBUILT_STATIC_LIBRARY)

# ─── Prebuilt: libcrypto ──────────────────────────────
include $(CLEAR_VARS)
LOCAL_MODULE            := libcrypto
LOCAL_SRC_FILES         := loginUtils/openssl/$(TARGET_ARCH_ABI)/lib/libcrypto.a
LOCAL_EXPORT_C_INCLUDES := loginUtils/openssl/$(TARGET_ARCH_ABI)/include
include $(PREBUILT_STATIC_LIBRARY)
```

Then link against these libraries in your module:

```makefile
LOCAL_STATIC_LIBRARIES := \
    libcrypto \
    libssl \
    libcurl
```

### Integration with CMake

For CMake-based projects, add the following to your CMakeLists.txt:

```cmake
# Define the library paths based on the ABI
set(LIBS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/loginUtils)

# Add OpenSSL libraries
add_library(ssl STATIC IMPORTED)
set_target_properties(ssl PROPERTIES IMPORTED_LOCATION
    ${LIBS_DIR}/openssl/${ANDROID_ABI}/lib/libssl.a)

add_library(crypto STATIC IMPORTED)
set_target_properties(crypto PROPERTIES IMPORTED_LOCATION
    ${LIBS_DIR}/openssl/${ANDROID_ABI}/lib/libcrypto.a)

# Add cURL library
add_library(curl STATIC IMPORTED)
set_target_properties(curl PROPERTIES IMPORTED_LOCATION
    ${LIBS_DIR}/curl/${ANDROID_ABI}/lib/libcurl.a)

# Include headers
include_directories(
    ${LIBS_DIR}/openssl/${ANDROID_ABI}/include
    ${LIBS_DIR}/curl/${ANDROID_ABI}/include
)

# Link the libraries to your target
target_link_libraries(your_target
    curl
    ssl
    crypto
    # other libraries...
)
```

## ChangeLog
| Date      | Content                                                              |
|-----------|----------------------------------------------------------------------|
| NOW EVERY NIGHT UTC 00:00 will autometically update to new version. |
| 2025.04.25 | OpenSSL 3.5.0 + CURL 8.13.0 |
| 2025.04.09 | OpenSSL 3.5.0 |
| 2025.02.12 | OpenSSL 3.4.1 |
| 2024.10.23 | OpenSSL 3.4.0 |
| 2024.09.04 | OpenSSL 3.3.2 |
| 2024.06.05 | OpenSSL 3.3.1 |
| 2024.04.10 | OpenSSL 3.3.0 |
| 2024.02.01 | OpenSSL 3.2.1 |
| 2023.11.24 | OpenSSL 3.2.0 |
| 2023.10.25 | OpenSSL 3.1.4 |
| 2023.09.21 | OpenSSL 3.1.3 |
| 2023.08.03 | OpenSSL 3.1.2 |
| 2023.06.05 | OpenSSL 3.1.1 |
| 2023.03.15 | OpenSSL 3.1.0 |
| 2023.02.09 | OpenSSL 3.0.8 |
| 2022.11.07 | OpenSSL 3.0.7 |
| 2022.07.14 | OpenSSL 3.0.5 |
| 2022.06.23 | OpenSSL 3.0.4 |
| 2022.05.19 | OpenSSL 3.0.3 |
| 2022.03.16 | OpenSSL 3.0.2 |
| 2021.12.24 | OpenSSL 3.0.1 |
| 2021.10.12 | OpenSSL 3.0.0 && `*MIPS` targets are no longer supported|
| 2021.09.08 | OpenSSL 1.1.1l |
| 2021.03.29 | OpenSSL 1.1.1k |
| 2021.02.18 | OpenSSL 1.1.1j |
| 2021.01.20 | OpenSSL 1.1.1i |
