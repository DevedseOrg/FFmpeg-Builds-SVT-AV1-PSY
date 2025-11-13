#!/bin/bash
# GPL static variant bundling VAAPI/QSV runtime for Battlemage (Intel Arc Pro) GPUs.
# Extends linux64-gpl but adds libva, libvpl, and media driver artifacts for a self-contained archive.

source "$(dirname "$BASH_SOURCE")"/linux-install-static.sh
source "$(dirname "$BASH_SOURCE")"/defaults-gpl.sh

# Keep master unless overridden; user can still pass release addin
# GIT_BRANCH inherited from defaults-gpl.sh

package_variant() {
    IN="$1"
    OUT="$2"

    # Base packaging (ffmpeg binaries, docs, man, presets)
    mkdir -p "$OUT/bin"
    cp "$IN/bin"/* "$OUT/bin"

    mkdir -p "$OUT/doc"
    cp -r "$IN/share/doc/ffmpeg"/* "$OUT/doc" 2>/dev/null || true

    mkdir -p "$OUT/man"
    cp -r "$IN/share/man"/* "$OUT/man" 2>/dev/null || true

    mkdir -p "$OUT/presets"
    cp "$IN/share/ffmpeg"/*.ffpreset "$OUT/presets" 2>/dev/null || true

    # VAAPI + QSV runtime bundle
    # Include libva shared libs, libvpl (if shared/static), and iHD media driver.
    # This allows hardware acceleration on systems without preinstalled Intel media stack.
    mkdir -p "$OUT/lib/dri"

    # libva (shared objects)
    cp -a "$IN/lib/libva.so"* "$OUT/lib/" 2>/dev/null || echo "[WARN] libva shared libs not found"
    cp -a "$IN/lib/libva-drm.so"* "$OUT/lib/" 2>/dev/null || true
    cp -a "$IN/lib/libva-x11.so"* "$OUT/lib/" 2>/dev/null || true

    # libvpl (may be static or shared depending on build flags; copy both possibilities)
    cp -a "$IN/lib/libvpl.so"* "$OUT/lib/" 2>/dev/null || true
    cp -a "$IN/lib/libvpl.a" "$OUT/lib/" 2>/dev/null || true

    # Media driver (Battlemage runtime)
    cp -a "$IN/lib/dri/iHD_drv_video.so" "$OUT/lib/dri/" 2>/dev/null || echo "[WARN] iHD media driver not found (intel-media-driver stage may have been skipped)"

    # Minimal license harvesting (best-effort)
    mkdir -p "$OUT/licenses"
    for pc in libva vpl; do
        if [[ -f "$IN/lib/pkgconfig/${pc}.pc" ]]; then
            echo "Source: ${pc}" > "$OUT/licenses/${pc}.LICENSE.txt"
            echo "Refer to upstream repository for full license text." >> "$OUT/licenses/${pc}.LICENSE.txt"
        fi
    done

    # Wrapper script to set LIBVA_DRIVERS_PATH relative to extraction directory
    cat > "$OUT/bin/ffmpeg-battlemage" <<'EOS'
#!/bin/bash
# Wrapper ensuring VAAPI driver discovery for bundled Battlemage stack.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_ROOT="${SCRIPT_DIR%/bin}/lib"
export LIBVA_DRIVERS_PATH="${LIB_ROOT}/dri"
exec "${SCRIPT_DIR}/ffmpeg" "$@"
EOS
    chmod +x "$OUT/bin/ffmpeg-battlemage"
}
