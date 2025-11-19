

# ANGLE with MoltenVK Backend on macOS  
Build Instructions + Xcode Integration Guide

This document describes:

Part 1 - How to build ANGLE with the MoltenVK (Vulkan→Metal) backend  
Part 2 - How to integrate the built libraries into Xcode


# Part 1 - Building ANGLE with MoltenVK Backend

### 1.1.a Using CI-built ANGLE

Download the CI artifacts.

### 1.1.b Or you can build locally
1. Switch to `MoltenVK-backend` branch on `angle-builder` repo.
2. copy and run `mac-local-build.sh` inside /angle folder


### 1.2 Replace output files, for example
- `/app/angle/out/include`
- `/app/angle/out/Debug`
- `/app/angle/out/Release`



# Part 2 — Integrating ANGLE into Xcode

### 2.1 Get MotelnVK library files from Vulkan SKD
- Downlaod from https://vulkan.lunarg.com/sdk/home
  * MoltenVK is included in Vulkan SDK

 - Copy library files from Vulkan SDK. We only need followings

```
/app/vulkan
    libMoltenVK.dylib
    libvulkan.1.4.328.dylib (version number can be different)
    libvulkan.1.dylib
    MoltenVK_icd.json
```


`*.dylib` files should be copied into App `Framework` folder.

`libvulkan.1.dylib` is a symlink, has to be recreated on demand.

`MoltenVK_icd.json`, should be edited, copied into App `Resources` folder.

