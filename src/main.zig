const std = @import("std");
const c = @import("c.zig");
const panic = std.debug.panic;
const warn = std.debug.warn;
const gl = @import("opengl_bindings.zig");
const Colors = @import("Colors.zig");


fn float(value: u32) callconv(.Inline) f32
{
    return @intToFloat(f32, value);
}

// necessary to load OpenGL functions
fn wrapper(ctx: void, entry_point: [:0]const u8) ?*anyopaque
{
    _ = ctx;
    return c.SDL_GL_GetProcAddress(entry_point);
}

const kNumPoints:c_int = 5;
const kMsaaSampleCount: c_int = 0;
const kStencilBits: c_int = 8;

// not tested - do not use
fn create_star() ?*c.sk_path_t
{
    var concavePath = c.sk_path_new();
    var rot = c.sk_matrix44_new();
    var points: [kNumPoints]c.sk_point_t = undefined;
    
    c.sk_matrix44_set_rotate_about_radians(rot, 0.0, 0.0, 0.0, float(360/kNumPoints));

    {
        var i: usize = 1;
        while(i < kNumPoints - 1) : (i += 1)
        {
            c.sk_matrix_map_points(&rot, points[i], points[i+1] - 1, 1);
        }
    }
    c.sk_path_move_to(&concavePath, 33.0, 64.0);
    {
        var i: usize = 0;
        while(i < kNumPoints) : (i += 1)
        {
            c.sk_path_line_to(&concavePath, 78.0, 63.0);
        }
    }
    c.sk_path_set_filltype(concavePath, c.kEvenOdd);
    c.sk_path_close(concavePath);

    return concavePath;    
}



pub fn main() !void {

    // GL 3.0 + GLSL 130
    var glsl_version = "#version 130";
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_FLAGS, 0);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_PROFILE_MASK, c.SDL_GL_CONTEXT_PROFILE_CORE);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MINOR_VERSION, 0);


    // and prepare OpenGL stuff
    _ = c.SDL_SetHint(c.SDL_HINT_RENDER_DRIVER, "opengl");
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_DEPTH_SIZE, 24);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_STENCIL_SIZE, 8);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_DOUBLEBUFFER, 1);
    var current: c.SDL_DisplayMode = undefined;
    var dm: c.SDL_DisplayMode = undefined;
    _ = c.SDL_GetCurrentDisplayMode(0, &current);

    var window = c.SDL_CreateWindow("SDL-cimgui-Skia_example", 0, 0, 1024, 768, c.SDL_WINDOW_SHOWN | c.SDL_WINDOW_OPENGL | c.SDL_WINDOW_RESIZABLE);
    var gl_context = c.SDL_GL_CreateContext(window);

    gl.load({}, wrapper) catch
    {
        panic("failed to initialize GL functions\n", .{});
    };

    if(c.SDL_GetDesktopDisplayMode(0, &dm) != 0)
    {
        std.debug.print("display mode warning\n", .{});
    }

    var dw: c_int = undefined;
    var dh: c_int = undefined;
    _ = c.SDL_GL_GetDrawableSize(window, &dw, &dh);
    std.debug.print("w:{d}  h:{d}\n", .{dw, dh});
    
    _ = c.SDL_GL_SetSwapInterval(1);        // enable vsync
    _ = c.Do_gl3wInit();                    // initialize OpenGL loader for cimgui_sdl
  
    _ = c.igCreateContext(null);
    _ = c.ImGui_ImplSDL2_InitForOpenGL(window, gl_context);
    _ = c.ImGui_ImplOpenGL3_Init(glsl_version);
    _ = c.igStyleColorsDark(null);

    defer _ = c.ImGui_ImplOpenGL3_Shutdown();
    defer _ = c.ImGui_ImplSDL2_Shutdown();
    defer _ = c.igDestroyContext(null);
    defer _ = c.SDL_GL_DeleteContext(gl_context);
    defer _ = c.SDL_DestroyWindow(window);
    defer _ = c.SDL_Quit(); 

    var showDemoWindow: bool = true;
    var showAnotherWindow: bool = false;
    var clearColor = c.ImVec4{ .x = 0.45, .y = 0.55, .z = 0.60, .w = 1.00 };

    // Skia functions
    var interface = c.gr_glinterface_create_native_interface();
    var context = c.gr_direct_context_make_gl(interface);
    var buffer: gl.GLint = undefined;
    gl.getIntegerv(gl.FRAMEBUFFER_BINDING, &buffer);
    
    var info = c.gr_gl_framebufferinfo_t
    { 
        .fFBOID = @intCast(c_uint, buffer),
        .fFormat = @as(c_uint, gl.RGB8),
    };

    var target = c.gr_backendrendertarget_new_gl(
        dw,                                         // int width,
        dh,                                         // int height,
        kMsaaSampleCount,                           // int samples,
        kStencilBits,                               // int stencils,
        &info                                       // const gr_gl_framebufferinfo_t* glInfo
    );
    
    var props = c.sk_surfaceprops_new(
        0,                              //uint32_t flags, --> sk_surfaceprops_flags_t
        c.RGB_H_SK_PIXELGEOMETRY,       // c.sk_pixelgeometry_t.RGB_H_SK_PIXELGEOMETRY
    );
    // var props = c.sk_surface_t.Props.kLegacyFontHost_InitType();


    var surface = c.sk_surface_new_backend_render_target(
        @ptrCast(?*c.gr_recording_context_t, context),  // gr_recording_context_t* context,
        target,                                         // const gr_backendrendertarget_t* target,
        c.BOTTOM_LEFT_GR_SURFACE_ORIGIN,                // c.gr_surfaceorigin_t.BOTTOM_LEFT_GR_SURFACE_ORIGIN,
        c.RGB_888X_SK_COLORTYPE,                        // c.sk_colortype_t.RGB_888X_SK_COLORTYPE, // colorType,
        null,                                           // sk_colorspace_t* colorspace,
        props,                                          //const sk_surfaceprops_t* props
    );

    // const _dw = @intCast(u32, dw);
    // const _dh = @intCast(u32, dh);
    // const _dmw = @intCast(u32, dm.w);
    // const _dmh = @intCast(u32, dm.h);
    var canvas = c.sk_surface_get_canvas(surface);
    c.sk_canvas_scale(canvas, 0.8, 0.8);
    // c.sk_canvas_scale(canvas, float(_dw/_dmw), float(_dh/_dmh));

    const helpMessage = "message to render";
    var paint = c.sk_paint_new();
    var font = c.sk_font_new_with_values(
        c.sk_typeface_create_default(),     // sk_typeface_t* typeface,
        12.0,                               // float size,
        4.0,                                // float scaleX,
        0.0                                 // float skewX
    );     

    c.sk_paint_set_color(paint, Colors.Green);
    
    var running: bool = true;
    while(running)
    {
        var e: c.SDL_Event = undefined;
        while(c.SDL_PollEvent(&e) != 0)
        {
            _ = c.ImGui_ImplSDL2_ProcessEvent(&e);
            if(e.type == c.SDL_QUIT) running = false;
            if(e.type == c.SDL_WINDOWEVENT and e.window.event == c.SDL_WINDOWEVENT_CLOSE and e.window.windowID == c.SDL_GetWindowID(window)) running = false;
        }

        // render ImGUI
        // start imgui_frame
        _ = c.ImGui_ImplOpenGL3_NewFrame();
        _ = c.ImGui_ImplSDL2_NewFrame(window);
        _ = c.igNewFrame();

        if(showDemoWindow) c.igShowDemoWindow(&showDemoWindow);

        {
            var f: f32 = undefined;
            // var counter: c_int = undefined;
            _ = c.igBegin("hello box", null, 0);
            _ = c.igText("this is text");
            _ = c.igCheckbox("demo window", &showDemoWindow);
            _ = c.igCheckbox("another window", &showAnotherWindow);
            _ = c.igSliderFloat("float", &f, 0.0, 1.0, "%.3f", 0);
            // _ = c.igColorEdit3("clear color", ())

            _ = c.igEnd();
        }

        if(showAnotherWindow)
        {
            _ = c.igBegin("another window", &showAnotherWindow, 0);
            _ = c.igText("hello from imgui");
            _ = c.igEnd();
        }

        _ = c.igRender();
        _ = c.SDL_GL_MakeCurrent(window, gl_context);
        // _ = c.glViewport(0, 0, ioptr.DisplaySize.x, ioptr.DisplaySize.y);
        _ = c.glViewport(0, 0, 1024, 768);
        _ = c.glClearColor(clearColor.x, clearColor.y, clearColor.z, clearColor.w);
        _ = c.glClear(c.GL_COLOR_BUFFER_BIT);
        _ = c.ImGui_ImplOpenGL3_RenderDrawData(c.igGetDrawData());



        // render Skia                              ---> renders nothing...
        c.sk_canvas_clear(canvas, Colors.Orange);
        const rect = c.sk_rect_t
        {
            .left = 93.0,
            .top = 156.0,
            .bottom = 278.0,
            .right = 32.0, 
        };
        c.sk_canvas_draw_rect(canvas, &rect, paint);
        _ = font;
        _ = helpMessage;        

        // c.sk_canvas_draw_simple_text(
        //     canvas,                     // sk_canvas_t* canvas,
        //     helpMessage,                // const void* text,
        //     helpMessage.len,            // size_t byte_length,
        //     c.UTF8_SK_TEXT_ENCODING,
        //     120.0,                      //float x,
        //     320.0,                      // float y,
        //     font,                       // const sk_font_t* cfont,
        //     paint                       // const sk_paint_t* cpaint
        // );

        c.gr_direct_context_flush_and_submit(context, false);


        _ = c.SDL_GL_SwapWindow(window);
    }
}

