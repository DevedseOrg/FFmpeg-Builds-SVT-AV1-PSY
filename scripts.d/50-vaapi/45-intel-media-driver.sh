#!/bin/bash

SCRIPT_REPO="https://github.com/intel/media-driver.git"
SCRIPT_COMMIT="192fe0f5478bdfacfc8df6fa768e5ac699b73924"  # intel-media-25.3.4

ffbuild_enabled() {
    [[ $TARGET != linux64 ]] && return -1
    return 0
}

ffbuild_dockerbuild() {
    mkdir build && cd build

    # Add -Wno-error=array-bounds to work around GCC 15+ false positives
    export CFLAGS="${CFLAGS} -Wno-error=array-bounds"
    export CXXFLAGS="${CXXFLAGS} -Wno-error=array-bounds"

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
