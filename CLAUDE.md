# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **build pipeline** for Google's ANGLE (Almost Native Graphics Layer Engine) targeting macOS. It produces universal (arm64 + x64) dylibs with Metal and Vulkan (via MoltenVK) backends, customized for integration into TroikaTronix Isadora.

The repo itself contains no C++ source code to compile directly. Instead it manages:
- A pinned ANGLE checkout (via `gclient` and `.gclient`)
- Custom patches applied to ANGLE source (`patches/`)
- Build configuration (GN args) and automation (`mac-local-build.sh`)
- CI/CD via GitHub Actions (`.github/workflows/ci-macOS.yaml`)

## Build Commands

### Prerequisites
- `depot_tools` must be installed and on PATH (`gclient`, `gn`, `autoninja`)
- macOS with Xcode (for Metal SDK)

### Full local build (fetches source, patches, builds, and merges)
```bash
./mac-local-build.sh
```

### Individual build steps (run from inside `angle/` directory)
```bash
# Fetch/sync ANGLE at pinned revision
gclient sync --no-history --shallow -D --revision <REVISION>

# Apply Isadora patches
cd angle && git am ../patches/*.patch

# Generate build files for a specific arch
gn gen out/Debug/arm64 --args='<GN_ARGS> target_cpu="arm64" is_debug=true'

# Compile
autoninja -C out/Debug/arm64 libEGL libGLESv2

# Merge into universal binary
lipo -create out/Debug/arm64/libEGL.dylib out/Debug/x64/libEGL.dylib -output out/Debug/libEGL.dylib

# Fix install names for @rpath linking
install_name_tool -id @rpath/libEGL.dylib out/Debug/libEGL.dylib
```

### List all GN build flags with explanations
```bash
cd angle && gn args out/Debug/arm64 --list
```

## Architecture

### Key files
| File | Purpose |
|------|---------|
| `mac-local-build.sh` | Main build script: fetch, patch, build (Debug+Release x arm64+x64), merge, fix install names |
| `.gclient` | Dependency config for `gclient sync`. Excludes ~30 unnecessary deps (Android, Chrome, etc.) to reduce ~2GB download |
| `.github/workflows/ci-macOS.yaml` | CI pipeline: parallel builds per arch/config, lipo merge, GitHub Release on `v*` tags |
| `patches/` | Custom patches applied via `git am` before build |

### ANGLE revision
The ANGLE commit hash is pinned in two places that must stay in sync:
- `mac-local-build.sh` → `REVISION` variable
- `.github/workflows/ci-macOS.yaml` → `env.ANGLE_REVISION`

### Custom patches (applied to ANGLE source)
1. **`0001-Skip-CPU-readback-for-IOSurface-output-path.patch`** — Bypasses CPU readback in `IOSurfaceSurfaceVkMac.mm` for GPU-only Syphon Metal data path
2. **`0002-Enable-VK_EXT_metal_objects-device-extension-on-Appl.patch`** — Enables `VK_EXT_metal_objects` in `vk_renderer.cpp` so MTLTexture can be extracted from VkImage via MoltenVK
3. **`0003-Support-predefined-Vulkan-border-colors-for-GL_CLAMP.patch`** — Enables `GL_EXT_texture_border_clamp` on MoltenVK by using predefined Vulkan border colors when `VK_EXT_custom_border_color` is unavailable
4. **`0004-Import-IOSurface-backed-VkImage-via-VK_EXT_metal_obj.patch`** — Creates the IOSurface pbuffer's VkImage IOSurface-backed via `VkImportMetalIOSurfaceInfoEXT` (BGRA8, non-planar), making `bindTexImage` zero-copy; falls back to the staged upload path otherwise

### Build outputs
- `angle/out/{Debug,Release}/libEGL.dylib` — Universal EGL library
- `angle/out/{Debug,Release}/libGLESv2.dylib` — Universal OpenGL ES 2.0/3.x library

### Critical GN args
- `angle_enable_gl=false` — **Must** be false, otherwise macOS won't use Metal backend
- `angle_enable_metal=true` — Enables Metal backend
- `angle_enable_vulkan=true` — Enables Vulkan backend (via MoltenVK)
- `is_component_build=false` — Produces single dylibs instead of many small ones
- `use_custom_libcxx=false` — Uses system libc++ for compatibility

### MoltenVK integration (branch: `MoltenVK-backend`)
For Vulkan backend via MoltenVK, additional Vulkan SDK libraries are needed at runtime:
- `libMoltenVK.dylib`
- `libvulkan.1.dylib` (symlink)
- `MoltenVK_icd.json` (ICD manifest, goes in app Resources)

See `build-with-MotlenVK.md` for Xcode integration details.

### CI/CD flow
1. Triggered on `v*` tags or PRs to main/develop
2. Builds 4 variants in parallel: {Debug, Release} x {arm64, x64}
3. Merges each config into universal binary via `lipo`
4. Applies `install_name_tool -id @rpath/...` to all dylibs
5. On tag push: packages with ANGLE headers into a GitHub Release zip
