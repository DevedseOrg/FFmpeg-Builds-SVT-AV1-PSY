#!/bin/bash

# libva build script
#
# Ordering assumptions:
#   gmmlib (43-gmmlib.sh) must be built before intel-media-driver (55-intel-media-driver.sh),
#   and libva must be present before the driver config runs (pkg-config usage).
# This script provides the VA-API headers and libraries consumed by the media driver.
#
# Runtime driver discovery:
#   We deliberately set -Ddriverdir to the prefix-local dri directory so packaged
#   builds can find the iHD driver without requiring LIBVA_DRIVERS_PATH.
#   If users relocate FFmpeg artifacts, they may still set LIBVA_DRIVERS_PATH manually.
#
# Version chosen for Battlemage support parity with Jellyfin builds.
SCRIPT_REPO="https://github.com/intel/libva.git"
SCRIPT_COMMIT="217da1c28336d6a7e9c0c4cb8f1c303968a675f1"  # 2.22.0

ffbuild_depends() {
    echo base
    echo x11
}

ffbuild_enabled() {
    [[ $ADDINS_STR == *4.4* && $TARGET == win* ]] && return -1
    [[ $ADDINS_STR == *5.0* && $TARGET == win* ]] && return -1
    [[ $ADDINS_STR == *5.1* && $TARGET == win* ]] && return -1
    [[ $ADDINS_STR == *6.0* && $TARGET == win* ]] && return -1
    [[ $TARGET == linuxarm64 ]] && return -1
    return 0
}

ffbuild_dockerbuild() {
    # This works around an issue of our libxcb-dri3 implib-wrapper not exporting data symbols.
    # Under normal circumstances, this would break horribly.
    # But we only want to generate another import lib for libva, so it doesn't matter.
    echo "#include <xcb/xcbext.h>" >> va/x11/va_dri3.c
    echo "xcb_extension_t xcb_dri3_id;" >> va/x11/va_dri3.c

    # Allow to actually toggle static linking
    sed -i "s/shared_library/library/g" va/meson.build

    mkdir mybuild && cd mybuild

    local myconf=(
        --prefix="$FFBUILD_PREFIX"
        --buildtype=release
        -Denable_docs=false
    )

    if [[ $TARGET == linux64 ]]; then
        myconf+=(
            --cross-file=/cross.meson
            --default-library=shared
            --sysconfdir="/etc"
            # Install driver path into the build prefix for self-contained packages
            -Ddriverdir="${FFBUILD_PREFIX}/lib/dri"
            -Ddisable_drm=false
            -Dwith_x11=yes
            -Dwith_glx=no
            -Dwith_wayland=no
        )
    elif [[ $TARGET == win* ]]; then
        myconf+=(
            --cross-file=/cross.meson
            --default-library=static
            -Dwith_win32=yes
        )
    else
        echo "Unknown target"
        return -1
    fi

    # Reset flags to the raw toolchain defaults to avoid leakage from prior stages
    export CFLAGS="$RAW_CFLAGS"
    export CXXFLAGS="$RAW_CXXFLAGS"
    export LDFLAGS="$RAW_LDFLAGS"

    meson "${myconf[@]}" ..
    ninja -j"$(nproc)"
    DESTDIR="$FFBUILD_DESTDIR" ninja install

    if [[ $TARGET == linux* ]]; then
        gen-implib "$FFBUILD_DESTPREFIX"/lib/{libva.so.2,libva.a}
        gen-implib "$FFBUILD_DESTPREFIX"/lib/{libva-drm.so.2,libva-drm.a}
        gen-implib "$FFBUILD_DESTPREFIX"/lib/{libva-x11.so.2,libva-x11.a}
        rm "$FFBUILD_DESTPREFIX"/lib/libva{,-drm,-x11}.so*

        echo "Libs: -ldl" >> "$FFBUILD_DESTPREFIX"/lib/pkgconfig/libva.pc
        # Ensure the expected driver directory exists for later media-driver install
        mkdir -p "$FFBUILD_DESTPREFIX"/lib/dri
    fi
}

ffbuild_configure() {
    echo --enable-vaapi
}

ffbuild_unconfigure() {
    echo --disable-vaapi
}
