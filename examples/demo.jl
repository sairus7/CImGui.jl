using CImGui
using CImGui.ImGuiGLFWBackend
using CImGui.ImGuiGLFWBackend.LibCImGui
using CImGui.ImGuiGLFWBackend.LibGLFW
using CImGui.ImGuiOpenGLBackend
using CImGui.ImGuiOpenGLBackend.ModernGL
using CImGui.ImGuiGLFWBackend.GLFW

include(joinpath(@__DIR__, "demo_window.jl"))

GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 2)
if Sys.isapple()
    GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE) # 3.2+ only
    GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE) # required on Mac
end

# create window
window = GLFW.CreateWindow(1280, 720, "Demo")
@assert window != C_NULL
GLFW.MakeContextCurrent(window)
GLFW.SwapInterval(1)  # enable vsync

# create OpenGL and GLFW context
window_ctx = ImGuiGLFWBackend.create_context(window.handle)
gl_ctx = ImGuiOpenGLBackend.create_context()

# setup Dear ImGui context
ctx = CImGui.CreateContext()

# enable docking and multi-viewport
io = CImGui.GetIO()
io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_DockingEnable
io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_ViewportsEnable

# setup Dear ImGui style
CImGui.StyleColorsDark()
# CImGui.StyleColorsClassic()
# CImGui.StyleColorsLight()

# load Fonts
# - If no fonts are loaded, dear imgui will use the default font. You can also load multiple fonts and use `CImGui.PushFont/PopFont` to select them.
# - `CImGui.AddFontFromFileTTF` will return the `Ptr{ImFont}` so you can store it if you need to select the font among multiple.
# - If the file cannot be loaded, the function will return C_NULL. Please handle those errors in your application (e.g. use an assertion, or display an error and quit).
# - The fonts will be rasterized at a given size (w/ oversampling) and stored into a texture when calling `CImGui.Build()`/`GetTexDataAsXXXX()``, which `ImGui_ImplXXXX_NewFrame` below will call.
# - Read 'fonts/README.txt' for more instructions and details.
fonts_dir = joinpath(@__DIR__, "..", "fonts")
fonts = unsafe_load(CImGui.GetIO().Fonts)
# default_font = CImGui.AddFontDefault(fonts)
# CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "Cousine-Regular.ttf"), 15)
# CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "DroidSans.ttf"), 16)
# CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "Karla-Regular.ttf"), 10)
# CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "ProggyTiny.ttf"), 10)
# CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "Roboto-Medium.ttf"), 16)
CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "Recursive Mono Casual-Regular.ttf"), 16)
CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "Recursive Mono Linear-Regular.ttf"), 16)
CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "Recursive Sans Casual-Regular.ttf"), 16)
CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "Recursive Sans Linear-Regular.ttf"), 16)
# @assert default_font != C_NULL

# creat texture for image drawing
# img_width, img_height = 256, 256
# image_id = ImGui_ImplOpenGL3_CreateImageTexture(img_width, img_height)

# setup Platform/Renderer bindings
ImGuiGLFWBackend.init(window_ctx)
ImGuiOpenGLBackend.init(gl_ctx)

try
    demo_open = true
    clear_color = Cfloat[0.45, 0.55, 0.60, 1.00]
    while !GLFW.WindowShouldClose(window)
        GLFW.PollEvents()
        # start the Dear ImGui frame
        ImGuiOpenGLBackend.new_frame(gl_ctx)
        ImGuiGLFWBackend.new_frame(window_ctx)
        CImGui.NewFrame()

        demo_open && @c ShowDemoWindow(&demo_open)

        # # show image example
        # CImGui.Begin("Image Demo")
        # image = rand(GLubyte, 4, img_width, img_height)
        # ImGui_ImplOpenGL3_UpdateImageTexture(image_id, image, img_width, img_height)
        # CImGui.Image(Ptr{Cvoid}(image_id), (img_width, img_height))
        # CImGui.End()

        # rendering
        CImGui.Render()
        GLFW.MakeContextCurrent(window)
        display_w, display_h = GLFW.GetFramebufferSize(window)
        glViewport(0, 0, display_w, display_h)
        glClearColor(clear_color...)
        glClear(GL_COLOR_BUFFER_BIT)
        ImGuiOpenGLBackend.render(gl_ctx)

        if unsafe_load(igGetIO().ConfigFlags) & ImGuiConfigFlags_ViewportsEnable == ImGuiConfigFlags_ViewportsEnable
            backup_current_context = glfwGetCurrentContext()
            igUpdatePlatformWindows()
            GC.@preserve gl_ctx igRenderPlatformWindowsDefault(C_NULL, pointer_from_objref(gl_ctx))
            glfwMakeContextCurrent(backup_current_context)
        end

        GLFW.SwapBuffers(window)
    end
catch e
    @error "Error in renderloop!" exception=e
    Base.show_backtrace(stderr, catch_backtrace())
finally
    ImGuiOpenGLBackend.shutdown(gl_ctx)
    ImGuiGLFWBackend.shutdown(window_ctx)
    CImGui.DestroyContext(ctx)
    GLFW.DestroyWindow(window)
end
