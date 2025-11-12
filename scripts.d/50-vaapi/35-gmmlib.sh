#!/bin/bash

SCRIPT_REPO="https://github.com/intel/gmmlib.git"
SCRIPT_COMMIT="da9cc29dee504acd34d4c7052579808ceff49eea"  # intel-gmmlib-22.5.5

ffbuild_enabled() {
    [[ $TARGET != linux64 ]] && return -1
    return 0
}

ffbuild_dockerbuild() {
    mkdir build && cd build

    cmake \
        -G Ninja \
        -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX" \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DBUILD_SHARED_LIBS=OFF \
        ..

    ninja -j$(nproc)
    DESTDIR="$FFBUILD_DESTDIR" ninja install
}
