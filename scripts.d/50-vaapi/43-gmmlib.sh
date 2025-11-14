#!/bin/bash

SCRIPT_REPO="https://github.com/intel/gmmlib.git"
SCRIPT_COMMIT="d6571241f1d9663c1a4104962cf4e0816f0e6387"  # intel-gmmlib-22.8.2

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
    
    # Cleanup handled by run_stage.sh globally
}
