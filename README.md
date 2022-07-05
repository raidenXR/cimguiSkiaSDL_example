## Example of ImGUI and Skia on SDL2 window

Get precompiled Skia binary from [SkiaSharp.NativeAssets.Linux.NoDependencies](https://www.nuget.org/packages/SkiaSharp.NativeAssets.Linux.NoDependencies/2.88.1-preview.79) . Same goes for HarfBuzzSharp.

It compiles and it is running. However, there is a problem with rendering `sk_surface`.
To build add in `native` directory binaries of statically linked libs
- cimgui_sdl
- SkiaSharp
- HarfBuzzSharp

