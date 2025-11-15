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
    # intel-media-driver 25.3.4 has code that triggers array-bounds warnings
    # in GCC 15.2.0 (specifically in media_ddi_encode_hevc.cpp:55)
    # Jellyfin uses GCC 13 so doesn't hit this issue
    export CFLAGS="${CFLAGS} -Wno-error=array-bounds"
    export CXXFLAGS="${CXXFLAGS} -Wno-error=array-bounds"

    # Ensure target driver directory exists (matches libva -Ddriverdir)
    mkdir -p "$FFBUILD_PREFIX/lib/dri"

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

    # Reduce parallel jobs for this massive build to limit peak disk usage
    ninja -j2
    DESTDIR="$FFBUILD_DESTDIR" ninja install
    
    # Immediate aggressive cleanup before run_stage.sh to free space ASAP
    cd ..
    rm -rf build
}
