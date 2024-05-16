package doric

/*

Completed :
  Fixed memory leaks (add areans)
  Use the entity struct in the library as a base for the Entity the User uses

TODO: 
  Show clicked entity info entity on click
  Mouse control moving around the game

BUGS:
  Make sure the bounds are correct
  Highlight bounds?


  Player :: struct {
    dr_entity : using DoricEntity,
  }

  Edit mode and game mode
  Font adding 
  Finalize where the user defines the EntityTypes
*/

import gl "vendor:OpenGL"
import "core:thread"
import "core:mem/virtual"
import "core:math/linalg"
import "core:fmt"
import "base:runtime"
import "vendor:glfw"

import im "./odin-imgui"
import "./odin-imgui/imgui_impl_glfw"
import "./odin-imgui/imgui_impl_opengl3"

PlatformType :: enum {
    GLFW, //only support GLFW now

    //WIN32,
    //X11,
}

vec2        :: linalg.Vector2f32
vec3        :: linalg.Vector3f32
vec3i       :: [3]i32
vec2i       :: [2]i32
vec4        :: linalg.Vector4f32
EntityIndex :: distinct u32



ButtonState :: struct{
    //stores if the key is up or down
    ended_down      : bool,

    //stores if there was change in the key in this frame
    half_trans_count: i32,

    /*
	we can get the pressed and release
	pressed = half_trans_count is >0 and ended_down = false
	release = half_trans_count is >0 and ended_down = true
    */
}

Button :: enum {
    MOVE_UP,
    MOVE_DOWN,
    MOVE_LEFT,
    MOVE_RIGHT,
    ACTION_UP,
    ACTION_DOWN,
    ACTION_LEFT,
    ACTION_RIGHT,
    LEFT_SHOULDER,
    RIGHT_SHOULDER,
    BACK,
    ENTER,
    ESCAPE,
    SPACE,
    DEL,
    F1,
    F2,
    F3,
    MOUSE_LEFT,
    MOUSE_RIGHT,
    CTRL,
}

//reprensets one input device, i.e keyboard, gamepad 
ControllerInput :: struct {
    is_connected, is_analog: b32,
    stick_x, stick_y : f32,
    buttons : [Button]ButtonState,
}

GameInput :: struct{
    dt_for_frame  : f32,
    mouse_x, mouse_y, mouse_z : f64,
    mouse_buttons : ButtonState,
    controllers   : [2]ControllerInput,
}



process_keyboard_input :: proc (button: ^ButtonState, is_down: bool){
    if(button.ended_down != is_down){
	button.ended_down = is_down;
	button.half_trans_count += 1
    }
}


is_pressed :: proc(button: Button, index: int= 0) -> bool{
    input := &state.input
    using Button
    keyboard_input := &state.input.controllers[index]

    key := keyboard_input.buttons[button]
    return key.ended_down && (key.half_trans_count >0)
}

is_down :: proc(button: Button, index: int= 0) -> bool{
    input := &state.input
    using Button
    keyboard_input := &state.input.controllers[index]

    key := keyboard_input.buttons[button]
    return key.ended_down
}

process_inputs :: proc(){
    keyboard_input := &state.input.controllers[0]
    keyboard_input.is_connected = true;
    keyboard_input.is_analog    = false;

    for button in &keyboard_input.buttons{
	button.half_trans_count = 0;
    }
    buttons := &keyboard_input.buttons
    window := state.window

    using glfw

    process_keyboard_input(&buttons[.MOVE_UP],GetKey(window, KEY_W) == PRESS)
    process_keyboard_input(&buttons[.MOVE_DOWN], GetKey(window, KEY_S) == PRESS)
    process_keyboard_input(&buttons[.MOVE_LEFT],GetKey(window, KEY_A) == PRESS)
    process_keyboard_input(&buttons[.MOVE_RIGHT],GetKey(window, KEY_D) == PRESS)
    process_keyboard_input(&buttons[.ACTION_UP ],GetKey(window, KEY_UP) == PRESS)
    process_keyboard_input(&buttons[.ACTION_DOWN],GetKey(window, KEY_DOWN) == PRESS)
    process_keyboard_input(&buttons[.ACTION_LEFT],GetKey(window, KEY_LEFT) == PRESS)
    process_keyboard_input(&buttons[.ACTION_RIGHT], GetKey(window, KEY_RIGHT) == PRESS)
    process_keyboard_input(&buttons[.LEFT_SHOULDER],GetKey(window, KEY_Q) == PRESS)
    process_keyboard_input(&buttons[.RIGHT_SHOULDER],GetKey(window, KEY_E) == PRESS)
    process_keyboard_input(&buttons[.BACK],GetKey(window, KEY_BACKSPACE) == PRESS)
    process_keyboard_input(&buttons[.ENTER],GetKey(window, KEY_ENTER) == PRESS)
    process_keyboard_input(&buttons[.ESCAPE],GetKey(window, KEY_ESCAPE) == PRESS)
    process_keyboard_input(&buttons[.SPACE],GetKey(window, KEY_SPACE) == PRESS)
    process_keyboard_input(&buttons[.F1],GetKey(window, KEY_F1) == PRESS)
    process_keyboard_input(&buttons[.F2],GetKey(window, KEY_F2) == PRESS)
    process_keyboard_input(&buttons[.F3],GetKey(window, KEY_F3) == PRESS)
    process_keyboard_input(&buttons[.DEL],GetKey(window, KEY_DELETE) == PRESS)
    process_keyboard_input(&buttons[.MOUSE_LEFT], GetMouseButton(window, MOUSE_BUTTON_LEFT) == PRESS)
    process_keyboard_input(&buttons[.MOUSE_RIGHT], GetMouseButton(window, MOUSE_BUTTON_RIGHT) == PRESS)
    process_keyboard_input(&buttons[.CTRL], GetKey(window, KEY_LEFT_CONTROL) == PRESS)
}



DoricState :: struct{
    has_imgui  : bool, //support for microui
    initilized : bool,
    platform   : PlatformType,

    window     : glfw.WindowHandle,

    cursorPos, size, pos : vec2i,

    fullscreen : bool,

    uniforms : gl.Uniforms,
    program_id : u32, //support multiple programs
    input : GameInput,
    running : b32,

    world : World,
    game  : GameState,
    asset : ^Asset,

    sim_region : ^SimRegion,
    pool : thread.Pool,
    //gl_conf : GlConfig;

    //add arenas
    allocator      : runtime.Allocator,
    temp_allocator : runtime.Allocator,
    arena          : virtual.Arena, //static arena
    temp_arena     : virtual.Arena, //static arena
    picking_context : PickingContext,
}


GameState :: struct{
    entities :[dynamic]Entity
}

//The user of the library also should have the same state pointer
@private
state : ^DoricState

/*
    Initilize opengl
    create window
    set callbacks : set parameters and also default value
    GL major and minor version
    Initilize GameWorld

*/
Init :: proc (
    user_state : ^DoricState,
    width, height : i32,
    title: cstring,
    type : PlatformType
) -> bool {


    state = user_state
    viewport_callback :: proc "c" (window: glfw.WindowHandle, x, y: i32){
	state.pos = {x, y}
	gl.Viewport(0, 0, x, y);
    }

    scroll_callback :: proc "c" (window: glfw.WindowHandle, x, y: f64){
	//state.pos = {x, y}
	//gl.Viewport(0, 0, x, y);
	state.world.scale.z += f32(y) * 0.05
    }

    //initilize arena
    total_size : uint = runtime.Gigabyte * 2;
    err := virtual.arena_init_static(&state.arena,      total_size, total_size);
    err =  virtual.arena_init_static(&state.temp_arena, total_size, total_size);
    
    state.allocator      = virtual.arena_allocator(&state.arena);
    state.temp_allocator = virtual.arena_allocator(&state.temp_arena);

    context.allocator      = state.allocator
    context.temp_allocator = state.temp_allocator

    if !bool(glfw.Init())
    {
	return false
    }

    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 5)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)


    state.window = glfw.CreateWindow(width, height, title, nil, nil)
    glfw.MakeContextCurrent(state.window)
    gl.load_up_to(4, 5, glfw.gl_set_proc_address)
    glfw.SwapInterval(1)
    glfw.SetWindowSizeCallback(state.window, viewport_callback)
    gl.DebugMessageCallback(gl_debug_callback, nil);
    gl.DebugMessageControl(gl.DONT_CARE, gl.DONT_CARE, gl.DONT_CARE, 0, nil, gl.TRUE);

    glfw.SetScrollCallback(state.window, scroll_callback);
    gl.Viewport(0, 0, width, height)
    state.size.x = width
    state.size.y = height


    //initilize imgui 

    im.CHECKVERSION()
    im.CreateContext()
    io := im.GetIO()
    io.ConfigFlags += {.NavEnableKeyboard, .NavEnableGamepad}

    when im.IMGUI_BRANCH == "docking" {
	io.ConfigFlags += {.DockingEnable}
	io.ConfigFlags += {.ViewportsEnable}

	style := im.GetStyle()
	style.WindowRounding = 0
	style.Colors[im.Col.WindowBg].w = 1
    }


    im.StyleColorsDark()
    imgui_impl_glfw.InitForOpenGL(state.window, true)
    imgui_impl_opengl3.Init("#version 150")

    ok : bool
    state.program_id, ok = gl.load_shaders_file("vert.glsl", "frag.glsl")
    parse_all_asset_start()
    if !ok{
	fmt.eprintln("Failed to initilize shaders")
    }
    state.uniforms = gl.get_uniforms_from_program(state.program_id)
    gl.UseProgram(state.program_id)
    gl.FrontFace(gl.CW)
    gl.CullFace(gl.BACK)
    gl.Enable(gl.DEPTH_TEST)
    gl.Enable(gl.BLEND)

    initilize_world()

    add_entity({chunk  = { 0,0}, offset = {0,0}}, "")


    parse_all_asset_end()

    state.world.bounds[0] = {-1,-1}
    state.world.bounds[1] = {1,1}

	

    state.running = true
    state.has_imgui = true

    init_picking_texture()

    //Initialize picking texture


    return true
}

/**
    read inputs,
    clear screen, 
    initilize imgui frames  
    start simulation
**/
StartFrame :: proc(){
    context.allocator      = state.temp_allocator
    context.temp_allocator = state.temp_allocator

    glfw.PollEvents()
    process_inputs()
    gl.ClearColor(0.5,0.5,0.5,1)

    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
    imgui_impl_opengl3.NewFrame()
    imgui_impl_glfw.NewFrame()
    im.NewFrame()

    render_world_panel()

}

//End sim, Render entities,  Swap buffers
EndFrame :: proc(){

    render_entities(state.sim_region)

    free_all(state.temp_allocator)
    free_all(context.temp_allocator)
    im.Render()
    imgui_impl_opengl3.RenderDrawData(im.GetDrawData())

    when im.IMGUI_BRANCH == "docking" {
	backup_current_window := glfw.GetCurrentContext()
	im.UpdatePlatformWindows()
	im.RenderPlatformWindowsDefault()
	glfw.MakeContextCurrent(backup_current_window)
    }


    glfw.SwapBuffers(state.window)
    state.running = !glfw.WindowShouldClose(state.window)
}

//Use case example for the doric libaray 

//While defining and creating new entities
// add using base: Entity in the defination 
// call add_entity() after creating your own entity

//Create simple game

TEST_DORIC :: #config(TEST_DORIC, false)
when TEST_DORIC{

    EntityType :: enum{None, Player, Gravity, Stone, Wall, Gate }

    Player :: struct {
	using base: ^Entity,
	direction : u32,
    }

    add_player :: proc(){
	entity := add_entity({chunk  = { 0,0}, offset = {0,0}},   "wall_rough")
	player := new(Player)
	player.base = entity
	player.type = .Player
	player.varient = uintptr(player)
    }

    add_wall :: proc(){
	entity := add_entity({chunk  = { 0,0}, offset = {-1,0}},  "wall_rough")
	entity.type = .Wall
    }

    main :: proc (){

	dr_state : DoricState

	Init(&dr_state, 900, 900, "Hello", .GLFW)

	//add_entity({chunk  = { 0,0}, offset = {0,0}},   "wall_rough")
	//add_entity({chunk  = { 0,0}, offset = {1,0}},   "wall_rough")
	//add_entity({chunk  = { 0,0}, offset = {-1,0}},  "wall_rough")
	add_player()
	add_wall()

	for dr_state.running{


	    //Follow the same calling coventions ? 
	    StartFrame()

	    sim_region := begin_sim(state.world.center, state.world.bounds)

	    for &entity, i in &sim_region.entities{

		if !(entity.index > 0){
		    break
		}

		low := state.game.entities[u32(entity.index)]

		#partial switch low.type{
		case .Player:{
			//TOOD: the library should give some prebuilt functions to move player
		    if is_down(.MOVE_DOWN)    do entity.pos.y -= 0.01
		    if is_down(.MOVE_UP)      do entity.pos.y += 0.01
		    if is_down(.MOVE_LEFT)    do entity.pos.x -= 0.01
		    if is_down(.MOVE_RIGHT)   do entity.pos.x += 0.01
		}
		}
	    }


	    end_sim(sim_region)
	    EndFrame()
	}
    }
}
