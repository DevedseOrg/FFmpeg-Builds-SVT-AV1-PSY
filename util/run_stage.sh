#!/bin/bash
set -xe

export RAW_CFLAGS="$CFLAGS"
export RAW_CXXFLAGS="$CXXFLAGS"
export RAW_LDFLAGS="$LDFLAGS"
[[ -n "$STAGE_CFLAGS" ]] && export CFLAGS="$CFLAGS $STAGE_CFLAGS"
[[ -n "$STAGE_CXXFLAGS" ]] && export CXXFLAGS="$CXXFLAGS $STAGE_CXXFLAGS"
[[ -n "$STAGE_LDFLAGS" ]] && export LDFLAGS="$LDFLAGS $STAGE_LDFLAGS"

if [[ -n "$STAGENAME" && -f /cache.tar.xz ]]; then
    mkdir -p "/$STAGENAME"
    tar xaf /cache.tar.xz -C "/$STAGENAME"
    cd "/$STAGENAME"
elif [[ -n "$STAGENAME" ]]; then
    mkdir -p "/$STAGENAME"
    cd "/$STAGENAME"
fi

git config --global --add safe.directory "$PWD"

source "$1"
if [[ -z "$2" ]]; then
    ffbuild_dockerbuild
else
    "$2"
fi

# If this is a sub-stage, hardlink-copy the DESTDIR into the PREFIX.
# So the following layers can actually use the installed stuff.
if [[ "$SELF" == */??-*/??-*.sh && -d "$FFBUILD_DESTDIR" ]]; then
    cp -al "$FFBUILD_DESTDIR"/. /
fi

rm -rf "$FFBUILD_DESTPREFIX"/bin

if [[ -n "$STAGENAME" ]]; then
    # Aggressive cleanup to prevent disk exhaustion on GitHub Actions runners
    # Remove common build artifact patterns that consume GB of space
    cd "/$STAGENAME" 2>/dev/null || true
    
    # Clean CMake/Ninja/Make build directories (typically named 'build', 'mybuild', etc.)
    rm -rf build mybuild native_build .build 2>/dev/null || true
    
    # Clean object files, archives, and intermediate build products
    find . -type f \( -name '*.o' -o -name '*.lo' -o -name '*.a' -o -name '*.la' \) -delete 2>/dev/null || true
    
    # Clean .git directories from cloned sources (not needed after build)
    find . -type d -name '.git' -exec rm -rf {} + 2>/dev/null || true
    
    # Clean pkg-config build-time files (only runtime .pc files in DESTDIR matter)
    rm -rf .pc 2>/dev/null || true
    
    # Clean C++ template instantiation caches and dependency files
    find . -type f \( -name '*.d' -o -name '*.gcda' -o -name '*.gcno' \) -delete 2>/dev/null || true
    
    # Clean ninja/cmake metadata
    rm -rf .ninja_deps .ninja_log CMakeFiles CMakeCache.txt cmake_install.cmake 2>/dev/null || true
    
    cd /
    rm -rf "/$STAGENAME"
    
    # Force trim of any orphaned inodes
    sync || true
fi
