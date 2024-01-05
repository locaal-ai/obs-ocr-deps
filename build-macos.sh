#!/bin/bash
set -euox pipefail

CONFIG="${1?}"
TESSERACT_VERSION="${2?}"
LEPTONICA_VERSION="${3?}"

configure_and_build_tesseract() {
  ARCHITECTURE="$1"

  EXTRA_CMAKE_FLAGS=""
  # if arm64 disable AVX2, AVX, and SSE4.1 etc.
  if [ "$ARCHITECTURE" = "arm64" ]; then
    EXTRA_CMAKE_FLAGS="-DHAVE_AVX512F=OFF -DHAVE_AVX2=OFF -DHAVE_AVX=OFF -DHAVE_SSE4_1=OFF -DHAVE_NEON=OFF -DHAVE_FMA=OFF"
  fi

  # configure tesseract
  cmake tesseract-$TESSERACT_VERSION -B "tesseract_build_${CONFIG}_$ARCHITECTURE" \
    -DCMAKE_INSTALL_PREFIX="prerelease/tesseract/$CONFIG/$ARCHITECTURE" \
    -DCMAKE_BUILD_TYPE="$CONFIG" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0 \
    -DCMAKE_OSX_ARCHITECTURES="$ARCHITECTURE" \
    -DBUILD_SHARED_LIBS=OFF \
    -DLeptonica_DIR="$(pwd)/release/leptonica/$CONFIG/lib/cmake/leptonica" \
    -DUSE_SYSTEM_ICU=ON \
    -DBUILD_TRAINING_TOOLS=OFF \
    -DBUILD_TESTS=OFF \
    -DDISABLED_LEGACY_ENGINE=ON \
    -DDISABLE_TIFF=ON \
    -DDISABLE_CURL=ON \
    $EXTRA_CMAKE_FLAGS

  # build
  cmake --build "tesseract_build_${CONFIG}_$ARCHITECTURE"
  cmake --install "tesseract_build_${CONFIG}_$ARCHITECTURE" --prefix "prerelease/tesseract/$CONFIG/$ARCHITECTURE"
}

# configure leptonica
cmake leptonica-$LEPTONICA_VERSION -B "leptonica_build_$CONFIG" \
  -DCMAKE_INSTALL_PREFIX="release/leptonica/$CONFIG" \
  -DCMAKE_BUILD_TYPE="$CONFIG" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0 \
  -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" \
  -DBUILD_SHARED_LIBS=OFF \
  -DENABLE_ZLIB=OFF \
  -DENABLE_PNG=OFF \
  -DENABLE_GIF=OFF \
  -DENABLE_JPEG=OFF \
  -DENABLE_TIFF=OFF \
  -DENABLE_WEBP=OFF \
  -DENABLE_OPENJPEG=OFF

# build leptonica
cmake --build "leptonica_build_$CONFIG"
cmake --install "leptonica_build_$CONFIG" --prefix "release/leptonica/$CONFIG"

# configure and build tesseract for x86_64
configure_and_build_tesseract "x86_64"

# configure and build tesseract for arm64
configure_and_build_tesseract "arm64"

# ensure release/tesseract/$CONFIG/lib/ exists
mkdir -p "release/tesseract/$CONFIG/lib"

# create a universal binary for tesseract
lipo -create \
  "prerelease/tesseract/$CONFIG/x86_64/lib/libtesseract.a" \
  "prerelease/tesseract/$CONFIG/arm64/lib/libtesseract.a" \
  -output "release/tesseract/$CONFIG/lib/libtesseract.a"

# copy in the include, bin, and share directories
cp -r "prerelease/tesseract/$CONFIG/x86_64/include" "release/tesseract/$CONFIG/"
cp -r "prerelease/tesseract/$CONFIG/x86_64/bin" "release/tesseract/$CONFIG/"
cp -r "prerelease/tesseract/$CONFIG/x86_64/share" "release/tesseract/$CONFIG/"
# copy in the lib/pkgconfig and lib/cmake directories
cp -r "prerelease/tesseract/$CONFIG/x86_64/lib/pkgconfig" "release/tesseract/$CONFIG/lib/"
cp -r "prerelease/tesseract/$CONFIG/x86_64/lib/cmake" "release/tesseract/$CONFIG/lib/"
# copy leptonica static libraries
cp "release/leptonica/$CONFIG/lib/libleptonica.a" "release/tesseract/$CONFIG/lib/"

tar -C "release/tesseract/$CONFIG" -cvf "release/tesseract-macos-$TESSERACT_VERSION-$CONFIG.tar.gz" .
