#!/bin/bash

SCRIPT_REPO="https://github.com/intel/media-driver.git"
SCRIPT_COMMIT="714ca9c76a74b3119e021940c24928adf3b96e40"  # intel-media-25.4.3

ffbuild_depends() {
    echo gmmlib
    echo libva
    echo libdrm
}

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
        -DINSTALL_DRIVER_SYSCONF=OFF \
        -DLIBVA_DRIVERS_PATH="$FFBUILD_PREFIX/lib/dri" \
        -DBUILD_SHARED_LIBS=ON \
        ..

    ninja -j$(nproc)
    DESTDIR="$FFBUILD_DESTDIR" ninja install
}
