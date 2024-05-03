package doric

import gl "vendor:OpenGL"
import "core:thread"
import "core:math/linalg"
import "core:fmt"
import "core:image/png"
import "vendor:glfw"

PlatformType :: enum {
    GLFW, //only support GLFW now 
    //WIN32,
    //X11,
}

vec2 :: linalg.Vector2f32
vec3 :: linalg.Vector3f32
vec3i :: [3]i32
vec2i :: [2]i32
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

    cursorPos, size, pos : vec2,

    fullscreen : bool,

    uniforms : gl.Uniforms,
    program_id : u32, //support multiple programs
    input : GameInput,
    running : b32,

    world : World,
    game  : GameState,
    asset : ^Asset,

    pool : thread.Pool,
    //gl_conf : GlConfig;
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
	//state.pos = {x, y}
	gl.Viewport(0, 0, x, y);
    }

    if !bool(glfw.Init())
    {
	return false
    }

    state.window = glfw.CreateWindow(width, height, title, nil, nil)
    glfw.MakeContextCurrent(state.window)
    gl.load_up_to(4, 6, glfw.gl_set_proc_address)
    glfw.SwapInterval(1)
    glfw.SetWindowSizeCallback(state.window, viewport_callback)
    gl.Viewport(0, 0, width, height)

    ok : bool
    state.program_id, ok = gl.load_shaders_file("vert.glsl", "frag.glsl") 
    parse_all_asset_start()
    if !ok{
	fmt.eprintln("Failed to initilize shaders")
    }
    state.uniforms = gl.get_uniforms_from_program(state.program_id)

    initilize_world()

    add_entity({chunk  = { 0,0}, offset = {0,0}}, .None, "")


    parse_all_asset_end()

    state.running = true

    return true
}

/**
    read inputs,
    clear screen, 
    initilize imgui frames  
    start simulation
**/
StartFrame :: proc(){
    glfw.PollEvents()
    process_inputs()
    gl.ClearColor(0.5,0.5,0.5,1)
    gl.Clear(gl.COLOR_BUFFER_BIT)


    center : WorldPos = {chunk={0,0}, offset={0,0}}
    bounds : mat2 = {}
    bounds[0] = {-1,-1}
    bounds[1] = {1,1}
    sim_region := begin_sim(center, bounds)
    end_sim(sim_region)

    render_entities(sim_region)
}

//End sim, Render entities,  Swap buffers
EndFrame :: proc(){
	glfw.SwapBuffers(state.window)
	state.running = !glfw.WindowShouldClose(state.window)
}

//Use case example for the doric libaray 
TEST_DORIC :: #config(TEST_DORIC, false)
when TEST_DORIC{
    main :: proc (){

	dr_state : DoricState

	Init(&dr_state, 900, 900, "Hello", .GLFW)

	add_entity({chunk  = { 0,0}, offset = {0,0}}, .Player, "wall_rough")
	for dr_state.running{
	    StartFrame()

	    EndFrame()
	}

    }
}
