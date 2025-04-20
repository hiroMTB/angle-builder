[![Build ANGLE macOS Universal](https://github.com/hiroMTB/angle-builder/actions/workflows/ci-macOS.yaml/badge.svg)](https://github.com/hiroMTB/angle-builder/actions/workflows/ci-macOS.yaml)

# ANGLE library CI pipeline 

- Currently only support macOS(arm64, x64)

- dylibs are available in Release page


## macOS

- `dot.gclient_for_macOS` for `gclient sync` configuration(specify commit and select submodules to pull)

- Universal dylibs (arm64 and x64)

- Not codesigned, Not notalized

- Please run `install_name_tool` before linking. it depends on your usage, but the most standard way is below.

```bash
install_name_tool -id @rpath/libEGL.dylib your/path/to/libEGL.dylib
install_name_tool -id @rpath/libGLESv2.dylib your/path/to/libGLESv2.dylib
```


## Windows 11

- comming soon
