#!/bin/bash -e

WORK_PATH=$(cd "$(dirname "$0")"; pwd)

ANDROID_TARGET_API=$1
ANDROID_TARGET_ABI=$2
CURL_VERSION=$3
ANDROID_NDK_VERSION=$4
OPENSSL_VERSION=$5

if [ -z "$OPENSSL_VERSION" ]; then
    echo "Error: OpenSSL version parameter is required"
    echo "Usage: $0 <ANDROID_TARGET_API> <ANDROID_TARGET_ABI> <CURL_VERSION> <ANDROID_NDK_VERSION> <OPENSSL_VERSION>"
    exit 1
fi

ANDROID_NDK_PATH=${WORK_PATH}/android-ndk-${ANDROID_NDK_VERSION}
CURL_SRC=${WORK_PATH}/curl-${CURL_VERSION}
OUTPUT_PATH=${WORK_PATH}/curl_${CURL_VERSION}_${ANDROID_TARGET_ABI}
OPENSSL_PATH=${WORK_PATH}/openssl_${OPENSSL_VERSION}_${ANDROID_TARGET_ABI}
PEM_FILE=${WORK_PATH}/cacert.pem

if [ ! -d "${OPENSSL_PATH}" ]; then
    echo "Error: OpenSSL directory not found: ${OPENSSL_PATH}"
    exit 1
fi

if [ ! -f "${PEM_FILE}" ]; then
    echo "Error: cacert.pem not found!"
    exit 1
fi

if [ "$(uname -s)" == "Darwin" ]; then
    PLATFORM="darwin"
    export nproc="sysctl -n hw.logicalcpu"
else
    PLATFORM="linux"
    export nproc="nproc"
fi

function build() {
    mkdir -p ${OUTPUT_PATH}
    cd ${CURL_SRC}

    autoreconf -fi

    TOOLCHAIN=${ANDROID_NDK_PATH}/toolchains/llvm/prebuilt/${PLATFORM}-x86_64

    case "${ANDROID_TARGET_ABI}" in
        armeabi-v7a) HOST="armv7a-linux-androideabi" ;;
        arm64-v8a) HOST="aarch64-linux-android" ;;
        x86) HOST="i686-linux-android" ;;
        x86_64) HOST="x86_64-linux-android" ;;
        riscv64) HOST="riscv64-linux-android" ;;
        *) echo "Unsupported ABI: ${ANDROID_TARGET_ABI}"; exit 1 ;;
    esac

    export CC=${TOOLCHAIN}/bin/${HOST}${ANDROID_TARGET_API}-clang
    export AR=${TOOLCHAIN}/bin/llvm-ar
    export RANLIB=${TOOLCHAIN}/bin/llvm-ranlib
    export STRIP=${TOOLCHAIN}/bin/llvm-strip

    export CFLAGS="-fPIC -O2 --sysroot=${TOOLCHAIN}/sysroot -I${OPENSSL_PATH}/include"
    export LDFLAGS="--sysroot=${TOOLCHAIN}/sysroot -L${OPENSSL_PATH}/lib"

    ./configure \
        --host=${HOST} \
        --build=$(uname -m)-linux-gnu \
        --disable-shared \
        --enable-static \
        --with-openssl=${OPENSSL_PATH} \
        --disable-ldap --disable-ldaps --disable-manual \
        --disable-threaded-resolver --disable-unix-sockets --disable-proxy \
        --disable-ares --without-libpsl \
        --prefix=${OUTPUT_PATH} \
        CC=${CC} AR=${AR} RANLIB=${RANLIB} STRIP=${STRIP} \
        CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}"

    make -j$(${nproc})
    make install

    echo "Build completed with embedded PEM! Output at ${OUTPUT_PATH}"
}

function clean() {
    rm -rf ${OUTPUT_PATH}/bin ${OUTPUT_PATH}/share ${OUTPUT_PATH}/lib/pkgconfig
}

build
clean
