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

function embed_pem() {
    echo "Embedding cacert.pem..."
    HEADER="${CURL_SRC}/lib/embedded_cacert.h"

    echo 'static const char embedded_cacert[] =' > $HEADER
    awk '{print "\"" $0 "\\n\""}' ${PEM_FILE} >> $HEADER
    echo ';' >> $HEADER

    echo "embedded_cacert.h generated."

    echo "Patching cURL source..."

    PATCH_FILE="${CURL_SRC}/lib/vtls/openssl.c"

    if ! grep -q "embedded_cacert.h" "$PATCH_FILE"; then
        sed -i '/#include "urldata.h"/a #include "embedded_cacert.h"' "$PATCH_FILE"

        sed -i 's|if(data->set.str\[STRING_SSL_CAFILE\]) {|if(1) {|' "$PATCH_FILE"

        sed -i '/SSL_CTX_load_verify_locations/s|data->set.str\[STRING_SSL_CAFILE\]|NULL|' "$PATCH_FILE"

        sed -i "/SSL_CTX_load_verify_locations/i \ \ BIO* bio = BIO_new_mem_buf(embedded_cacert, -1);\n  X509_STORE* store = SSL_CTX_get_cert_store(backend->ctx);\n  if(!store || !bio) return CURLE_SSL_CERTPROBLEM;\n  while(1) {\n    X509* cert = PEM_read_bio_X509(bio, NULL, 0, NULL);\n    if(!cert) break;\n    X509_STORE_add_cert(store, cert);\n    X509_free(cert);\n  }\n  BIO_free(bio);" "$PATCH_FILE"
    fi
}

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

embed_pem
build
clean
