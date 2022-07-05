pub usingnamespace @cImport({
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", {});
    @cInclude("cimgui.h");
    @cInclude("cimgui_extras.h");
    @cInclude("cimgui_impl.h");
    @cInclude("SDL.h");
    @cInclude("SDL_opengl.h");
    @cInclude("GL/glu.h");    
    
    @cInclude("include/c/gr_context.h");      
    @cInclude("include/c/sk_canvas.h");
    @cInclude("include/c/sk_font.h");
    @cInclude("include/c/sk_typeface.h");
    @cInclude("include/c/sk_surface.h");       
    @cInclude("include/c/sk_matrix.h");       
    @cInclude("include/c/sk_path.h");       
    @cInclude("include/c/sk_paint.h");
    @cInclude("include/c/sk_types.h");              
});
