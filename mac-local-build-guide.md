# ANGLE Local Build Guide

This document provides step-by-step instructions for integrating ANGLE into the your macOS(and Windows later) app **without pulling unnecessary dependencies** like Android or Chrome-related code. ANGLE uses Google's custom build infrastructure including GN (Generate Ninja), a meta-build system, and Ninja, a fast build tool.

# Build with preconfigured settnigs
1. follow [Setting Up `depot_tools`](#1-setting-up-depot_tools)
2. follow [Clone ANGLE](#2-clone-angle-with-minimal-dependencies-and-shallow-copy)
3. run `mac-build-angle.sh`

# Build with your configuration 
Follow 1 ~ 6 below.

## 1. Setting Up `depot_tools`

`depot_tools` is a toolkit maintained by Google to fetch and build Chromium-based projects like ANGLE. 

### Installation
Refer to [Google's official documentation](https://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up)

### 🛠 Key Tools Overview

- **`fetch`** – Clones the repo and sets up dependencies.
- **`gclient`** – Manages dependencies and syncing.
- **`gn`** – Generates `ninja` build files from `args.gn` config.
- **`autoninja`** – A multi-threaded wrapper around `ninja`.


We have shell script for macOS build, after setting up `depot_tools`, you can just run `mac-build-angle.sh`


## 2. Clone ANGLE (with Minimal Dependencies and shallow copy)

Avoid using `fetch angle`, as it automatically runs `gclient sync` and pulls all dependencies, including many unnecessary ones (e.g. for Android, Chrome, DirectX). Instead, use our own `.gclient` and pull only necesarry code. Currently we only have custom `.gclient` file for macOS. Our dot.client_for_macOS file has `revision` parameter, this is a commit hash of angle repository. Please modify if you want to use different angle version. Also don't forget to add `--no-history` option for faster download. Depending on the configuration but, approx. 2GB less download size.

```bash
mv dot.gclient_for_macOS ./angle/.gclient
gclient sync --no-history
```

Some document mentioned about follwoing command for initial configuration. But it is almost empty and download everything, not recommended.

```bash
# open editor and cofigure without any option, avoid this
gclient config https://chromium.googlesource.com/angle/angle.git
```

Resulted angle folder should be around 3GB.

## 3. Configure Build with `gn`

GN uses an `args.gn` file to control the build configuration. 
Following command `gn gen --args` configures and generates `args.gn` in specified folder (e.g. `out/Release/arm64`)

```bash
gn gen out/Release/arm64 --args='is_debug=false \
target_cpu=\"arm64\" \
is_component_build=false \
angle_enable_gl = false \
angle_enable_metal = true \
use_custom_libcxx=false \
angle_build_tests=false \
build_with_chromium=false \
angle_enable_cl=false \
angle_enable_wgpu=false \
angle_enable_swiftshader=false \
angle_enable_hlsl=false \
angle_has_rapidjson=false \
angle_enable_overlay=false \
use_glib=false \
angle_enable_trace=false
'
```

- `is_component_build=true` generates lots of dylibs files, disable.
- `angle_enable_gl` must be `false` otherwise macOS won't use Metal
- see more options in `mac-local-build.sh` script.

## 4. Compile with `ninja`

Use `autoninja` to build efficiently across CPU cores:

```bash
autoninja -C out/Release/x64
```

This compiles ANGLE using your configuration.

## 5. Merge dylib files

Make a universal binary for arm64 and x64.

```bash
lipo -create  "out/Release/arm64/libEGL.dylib" \
              "out/Release/x64/libEGL.dylib"   \
              -output "out/Release/libEGL.dylib"

lipo -create  "out/Release/arm64/libGLESv2.dylib" \
              "out/Release/x64/libGLESv2.dylib" \
              -output "out/Release/libGLESv2.dylib"
```

## 6. set `install_name` (macOS only)

Angle will generate 2 dynamic library files, `libEGL.dylib` and `libGLESv2.dylib`. `install_name` is set to be `./libEGL.dylib` and `./libGLESv2.dylib`. 
We change these parameters with `@rpath/**.dylib` for better linking management.

```bash
install_name_tool -id @rpath/libEGL.dylib ./out/Debug/libEGL.dylib
install_name_tool -id @rpath/libGLESv2.dylib ./out/Debug/libGLESv2.dylib

```

## 6. Tips and Troubleshooting

- **Check your platform:** Avoid enabling DirectX on macOS or Metal on Windows.
- **Use `gn help`** for descriptions of build flags.

---

## References

- [ANGLE Git Repository](https://chromium.googlesource.com/angle/angle)
- [GN Build Docs](https://gn.googlesource.com/gn/)
- [Depot Tools Setup](https://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools.html)
