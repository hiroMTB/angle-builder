#!/bin/bash

cd angle

# on macOS, make sure angle_enable_gl=false, otherwise ANGLE won't use Metal

# Common GN args, some args are already false by default
# use `gn args out/Debug/arm64 --list` to see all args with explanations and default values
COMMON_ARGS='
is_component_build=false
use_custom_libcxx=false
angle_build_tests=false
build_with_chromium=false
angle_enable_d3d9=false
angle_enable_d3d11=false
angle_enable_gl=false
angle_enable_metal=true
angle_enable_vulkan=false
angle_enable_cl=false
angle_enable_wgpu=false
angle_enable_swiftshader=false
angle_enable_hlsl=false
angle_has_rapidjson=false
angle_build_vulkan_system_info=false
angle_enable_overlay=false
use_glib=false
angle_enable_trace=false
'

# Function to build for one config and merge x64 + arm64 into universal library
# Arguments:
#   1. config: Debug or Release
#   2. arch: arm64 or x64
#   3. libType: static or dylib
# Example usage:
#   build Debug arm64 static
#   build Release x64 dylib
build() {
  local config=$1
  local arch=$2
  local libType=$3
  local args="$COMMON_ARGS target_cpu=\"$arch\" mac_sdk_min=\"14\""

  if [ "$config" == "Debug" ]; then
    args="$args is_debug=true"
  elif [ "$config" == "Release" ]; then
    args="$args is_debug=false"
  else
    echo "Unknown config: $config"
    exit 1
  fi

  echo "Generating and building $config for $arch, args: $args"
  
  # Generate the build files
  gn gen out/$config/$arch --args="target_cpu=\"$arch\" $args"

  echo "start compiling"

  if [ "$libType" == "static" ]; then
    autoninja -C out/$config/$arch angle_static
  elif [ "$libType" == "dylib" ]; then
    autoninja -C out/$config/$arch libEGL libGLESv2
  else
    echo "Unknown library type: $libType"
    exit 1
  fi
}

# merge dylibs for a given config
# Arguments:
#   1. config: Debug or Release
#   2. libType: static or dylib
# Example usage:
#   merge Debug static
#   merge Release dylib
merge() {
  local config="$1"
    echo "Merging $config $2 with lipo..."
  
  if [ $2 == "static" ]; then
    lipo -create \
      "out/$config/arm64/obj/libEGL_static.a" \
      "out/$config/x64/obj/libEGL_static.a" \
      -output "out/$config/libEGL_static.a"

    lipo -create \
      "out/$config/arm64/obj/libGLESv2_static.a" \
      "out/$config/x64/obj/libGLESv2_static.a" \
      -output "out/$config/libGLESv2_static.a"
  elif [ $2 == "dylib" ]; then
    lipo -create \
      "out/$config/arm64/libEGL.dylib" \
      "out/$config/x64/libEGL.dylib" \
      -output "out/$config/libEGL.dylib"

    lipo -create \
      "out/$config/arm64/libGLESv2.dylib" \
      "out/$config/x64/libGLESv2.dylib" \
      -output "out/$config/libGLESv2.dylib"
  fi
}

# Build and merge both configs
build Debug arm64 dylib
build Debug x64 dylib
merge Debug dylib

build Release arm64 dylib
build Release x64 dylib
merge Release dylib

# TODO: static build seems supported but resulted .a files are too small like 200KB, can't make it work now
# build Debug arm64 static
# build Debug x64 static
# merge Debug static
# build Release arm64 static
# build Release x64 static
# merge Release static

# current install_name of dylib is ./libEGL.dylib, need to change it to @rpath/libEGL.dylib
install_name_tool -id @rpath/libEGL.dylib ./out/Debug/libEGL.dylib
install_name_tool -id @rpath/libGLESv2.dylib ./out/Debug/libGLESv2.dylib

echo 'Suscess building ANGLE'