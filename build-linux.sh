#!/bin/bash
set -euo pipefail

CONFIG="${1?}"
VERSION="${2?}"
ARCHITECTURE="x86_64"

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

# configure tesseract
cmake tesseract-$TESSERACT_VERSION -B "tesseract_build_${CONFIG}_$ARCHITECTURE" \
  -DCMAKE_INSTALL_PREFIX="release/tesseract/$CONFIG/$ARCHITECTURE" \
  -DCMAKE_BUILD_TYPE="$CONFIG" \
  -DBUILD_SHARED_LIBS=OFF \
  -DLeptonica_DIR="$(pwd)/release/leptonica/$CONFIG/lib/cmake/leptonica" \
  -DUSE_SYSTEM_ICU=ON \
  -DBUILD_TRAINING_TOOLS=OFF \
  -DBUILD_TESTS=OFF \
  -DDISABLED_LEGACY_ENGINE=ON \
  -DDISABLE_TIFF=ON \
  -DDISABLE_CURL=ON

# build
cmake --build "tesseract_build_${CONFIG}_$ARCHITECTURE"
cmake --install "tesseract_build_${CONFIG}_$ARCHITECTURE" --prefix "release/tesseract/$CONFIG/$ARCHITECTURE"

# copy leptonica static libraries to tesseract
cp -r "release/leptonica/$CONFIG/lib" "release/tesseract/$CONFIG/$ARCHITECTURE/lib"

tar -C "release/$CONFIG" -cvf "release/opencv-linux-$VERSION-$CONFIG.tar.gz" .

