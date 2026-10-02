#!/usr/bin/env bash
set -e

# =====================================================================
# ReadNext — Linux .deb & .tar.gz Packaging Script
# =====================================================================

VERSION=${1:-"1.0.0"}
BUNDLE_DIR=${2:-"build/linux/x64/release/bundle"}
OUTPUT_DIR="build/linux/installer"

echo "Building Linux packages for ReadNext v${VERSION}..."

if [ ! -d "$BUNDLE_DIR" ]; then
    echo "Error: Bundle directory not found at $BUNDLE_DIR"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# 1. Package .tar.gz Portable Archive
echo "Creating Portable tar.gz archive..."
tar -czvf "${OUTPUT_DIR}/ReadNext-v${VERSION}-Linux-x64.tar.gz" -C "$BUNDLE_DIR" .

# 2. Assemble Debian package structure
PKG_DIR="build/linux/deb_tree"
rm -rf "$PKG_DIR"
mkdir -p "${PKG_DIR}/DEBIAN"
mkdir -p "${PKG_DIR}/usr/lib/read_next"
mkdir -p "${PKG_DIR}/usr/bin"
mkdir -p "${PKG_DIR}/usr/share/applications"
mkdir -p "${PKG_DIR}/usr/share/pixmaps"

# Copy binary bundle
cp -r "${BUNDLE_DIR}/." "${PKG_DIR}/usr/lib/read_next/"

# Create executable wrapper in /usr/bin
cat << 'EOF' > "${PKG_DIR}/usr/bin/read_next"
#!/usr/bin/env bash
exec /usr/lib/read_next/read_next "$@"
EOF
chmod +x "${PKG_DIR}/usr/bin/read_next"

# Copy desktop launcher
cp packaging/linux/read_next.desktop "${PKG_DIR}/usr/share/applications/"

# Copy icon
if [ -f "assets/images/logo_icon.png" ]; then
    cp assets/images/logo_icon.png "${PKG_DIR}/usr/share/pixmaps/read_next.png"
fi

# Create Debian control file
cat << EOF > "${PKG_DIR}/DEBIAN/control"
Package: readnext
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Complex Innovators <contact@complexinnovators.com>
Depends: libgtk-3-0, liblzma5
Description: ReadNext - Advanced Professional PDF Viewer & Utility Suite
 ReadNext is an enterprise-grade, offline-first PDF reader, editor,
 annotation tool, and converter built with Flutter and native PDFium.
EOF

# Build .deb package
dpkg-deb --build "${PKG_DIR}" "${OUTPUT_DIR}/ReadNext-v${VERSION}-Linux-x64.deb"

echo "Linux packaging complete:"
ls -lh "$OUTPUT_DIR"
