package doric

import gl "vendor:OpenGL"
import "core:math/linalg"
import "core:fmt"
import "vendor:glfw"



/*
    picking texture is a way of finding out the entity index from screen position
    The vertex shader just takes in the model view projection matrix and sets the value of the texture
*/


PickingTexture :: struct {
    obj_id, draw_id, prim_id : u32, //What are draw_id and prim_id for
}

PickingContext :: struct {
    fbo, picking_tex, depth_tex, program_id : u32,
    uniforms          : gl.Uniforms,
    curr_entity       : ^Entity,
    selected_entities : [dynamic] u32,
}


init_picking_technique :: proc () -> bool {
    using state.picking_context

    ok : bool

    fmt.println("Loading picking shader")
    program_id, ok = gl.load_shaders_file("picking_vert.glsl", "picking_frag.glsl")

    if !ok {
	//Write that code that prints the shader errors
	fmt.print("Not Compile shader")
	return false
    }
    uniforms = gl.get_uniforms_from_program(program_id)
    return true
}

update_picking_texture :: proc(){
    context.allocator = state.allocator
    context.temp_allocator = state.temp_allocator
    using state.picking_context

    gl.UseProgram(program_id)

    //gl.GenFramebuffers(1, &fbo)
    gl.BindFramebuffer(gl.FRAMEBUFFER, fbo)
    gl.BindFramebuffer(gl.FRAMEBUFFER, fbo)
    gl.BindTexture(gl.TEXTURE_2D, picking_tex) 
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB32UI, state.size.x , state.size.y , 0, gl.RGB_INTEGER, gl.UNSIGNED_INT, nil)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
    gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, picking_tex, 0)
    gl.BindTexture(gl.TEXTURE_2D, depth_tex)
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.DEPTH_COMPONENT, state.size.x , state.size.y, 0, gl.DEPTH_COMPONENT, gl.FLOAT, nil)
    gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.TEXTURE_2D, depth_tex, 0)
    gl.BindTexture(gl.TEXTURE_2D, 0)
    gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
    gl.UseProgram(0)
}


//Can we do this without the depth buffer?
init_picking_texture :: proc() {
    context.allocator      = state.allocator
    context.temp_allocator = state.temp_allocator
    if init_picking_technique()
    {
	using state.picking_context
	gl.UseProgram(program_id)
	gl.GenFramebuffers(1, &fbo)
	gl.BindFramebuffer(gl.FRAMEBUFFER, fbo)
	gl.GenTextures(1, &picking_tex)
	gl.BindTexture(gl.TEXTURE_2D, picking_tex)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB32I, state.size.x , state.size.y, 0, gl.RGB_INTEGER, gl.UNSIGNED_INT, nil)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
	gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, picking_tex, 0)

	gl.GenTextures(1, &depth_tex)
	gl.BindTexture(gl.TEXTURE_2D, depth_tex)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.DEPTH_COMPONENT, state.size.x, state.size.y, 0, gl.DEPTH_COMPONENT, gl.FLOAT, nil)
	gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.TEXTURE_2D, depth_tex, 0)
	status := gl.CheckFramebufferStatus(gl.FRAMEBUFFER)

	gl.BindTexture(gl.TEXTURE_2D, 0)
	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
	gl.UseProgram(0)
    }
}


//returns the entity id
read_picking_pixels:: proc(){
    using state.picking_context

    gl.UseProgram(program_id)
    gl.BindFramebuffer(gl.FRAMEBUFFER, fbo)
    gl.ReadBuffer(gl.COLOR_ATTACHMENT0)

    pixels : [3]u32
    x, y := glfw.GetCursorPos(state.window)
    gl.ReadPixels(i32(x), state.size.y - i32(y), 1, 1, gl.RGB_INTEGER, gl.UNSIGNED_INT, &pixels)
    gl.ReadBuffer(gl.NONE)

    
    //NOTE(samrat) For now just one entity

    if pixels[0] > 0 && pixels[0] < u32(len(state.game.entities)){
	entity := &state.game.entities[pixels[0]]
	entity.flags += { .entity_flag_selected } 
	curr_entity = entity
	fmt.println(curr_entity)
    }else {
	curr_entity = nil
    }
    gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
}





















