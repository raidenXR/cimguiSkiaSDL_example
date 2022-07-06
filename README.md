## Example of ImGUI and Skia on SDL2 window

Get precompiled Skia binary from [SkiaSharp.NativeAssets.Linux.NoDependencies](https://www.nuget.org/packages/SkiaSharp.NativeAssets.Linux.NoDependencies/2.88.1-preview.79) . Same goes for HarfBuzzSharp. In order to compile the`include/c` directory with all the headers from the [mono-skia repo](https://github.com/mono/skia) is needed.

It compiles and it is running. However, there is a problem with rendering `sk_surface`.
To build make a `native` directory and add binaries of dynamically linked libs
- cimgui_sdl
- SkiaSharp
- HarfBuzzSharp

