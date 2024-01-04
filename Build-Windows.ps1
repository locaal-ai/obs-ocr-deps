Param($Configuration, $TesseractVersion, $LeptonicaVersion)

# configure leptonica
cmake leptonica-$LeptonicaVersion -B "leptonica_build_$Configuration" `
  -DCMAKE_INSTALL_PREFIX="release/leptonica/$Configuration" `
  -DCMAKE_BUILD_TYPE="$Configuration" `
  -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0 `
  -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" `
  -DBUILD_SHARED_LIBS=OFF `
  -DENABLE_ZLIB=OFF `
  -DENABLE_PNG=OFF `
  -DENABLE_GIF=OFF `
  -DENABLE_JPEG=OFF `
  -DENABLE_TIFF=OFF `
  -DENABLE_WEBP=OFF `
  -DENABLE_OPENJPEG=OFF `
  -DSW_BUILD=OFF

# build leptonica
cmake --build "leptonica_build_$Configuration" --config $Configuration
cmake --install "leptonica_build_$Configuration" --prefix "release/leptonica/$Configuration" --config $Configuration

# configure tesseract
cmake tesseract-$TesseractVersion -B "tesseract_build_${Configuration}" `
  -DCMAKE_INSTALL_PREFIX="release/tesseract/$Configuration" `
  -DCMAKE_BUILD_TYPE="$Configuration" `
  -DBUILD_SHARED_LIBS=OFF `
  -DLeptonica_DIR="$(Get-Location)/release/leptonica/$Configuration/lib/cmake/leptonica" `
  -DUSE_SYSTEM_ICU=ON `
  -DBUILD_TRAINING_TOOLS=OFF `
  -DBUILD_TESTS=OFF `
  -DDISABLED_LEGACY_ENGINE=ON `
  -DDISABLE_TIFF=ON `
  -DDISABLE_CURL=ON `
  -DSW_BUILD=OFF

# build
cmake --build "tesseract_build_${Configuration}" --config $Configuration
cmake --install "tesseract_build_${Configuration}" --config $Configuration --prefix release/tesseract/$Configuration

# copy leptonica static libs to tesseract lib folder
Copy-Item release\leptonica\$Configuration\lib\leptonica-$LeptonicaVersion.lib release\tesseract\$Configuration\lib

Compress-Archive release\tesseract\$Configuration\* release\tesseract-windows-$TesseractVersion-$Configuration.zip -Verbose

