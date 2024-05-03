package doric

import "core:math/linalg"
import "core:image/png"
import gl "vendor:OpenGL"
import "core:bytes"

/*
	While initiliing vao for each texture we initilize two vao (flat_vao and straight_vao)
	Each entity has Orientation enum which determines if it uses flat_vao or straight_vao
	In level editing mode everything uses flat_vao

	This technique is better than updating vao from flat_vao to straight vao is because different entites with same texture can have different oritentation
	In the final version of the game this shouldn't be done because creating a vao takes a long time
*/


GlConfig :: struct {
	program_id, font_program_id : u32,
	uniforms,   font_uniforms   : gl.Uniforms, 
}

GlContext :: struct {
	tex_handle, vbo, vao, ebo : u32,
}

TexHandle :: struct {
	img: ^png.Image,
	gl : GlContext,
	//gl_flat : GlContext,
}


vertices_font_straight:= []f32  {
	-0.1, -0.1,  0.1,  0.0, 0.0,    0.0,  0.0,  0.0, 1.0,
	0.1,  -0.1,  0.1,  1.0, 0.0,    0.0,  0.0,  0.0, 1.0,
	0.1,   0.1,  0.1,  1.0, 1.0,    1.0,  0.0,  0.0, 1.0,
	0.1,   0.1,  0.1,  1.0, 1.0,    1.0,  0.0,  0.0, 1.0,
	-0.1,  0.1,  0.1,  0.0, 1.0,    1.0,  0.0,  0.0, 1.0,
	-0.1, -0.1,  0.1,  0.0, 0.0,    0.0,  0.0,  0.0, 1.0,
};

vertices_flat := []f32  {
	                              // these are normal vectors
	-0.5, -0.5,  -0.5,  0.0, 1.0,   0.0, 1.0,  0.0,
	0.5, -0.5,   -0.5,  1.0, 1.0,   0.0, 1.0,  0.0,
	0.5, -0.5,    0.5,  1.0, 0.0,   0.0, 1.0,  0.0,
	0.5, -0.5,    0.5,  1.0, 0.0,   0.0, 1.0,  0.0,
	-0.5, -0.5,   0.5,  0.0, 0.0,   0.0, 1.0,  0.0,
	-0.5, -0.5,  -0.5,  0.0, 1.0,   0.0, 1.0,  0.0,
};

vertices_straight:= []f32  {
	                         //normal vectors
	-0.5, -0.5,   0.0,  0.0, 0.0,  0.0,  0.0, 1.0,
	 0.5, -0.5,   0.0,  1.0, 0.0,  0.0,  0.0, 1.0,
	 0.5, 0.5,   0.5,  1.0, 1.0,  0.0,  0.0, 1.0,
	 0.5, 0.5,   0.5,  1.0, 1.0,  0.0,  0.0, 1.0,
	-0.5, 0.5,   0.5,  0.0, 1.0,  0.0,  0.0, 1.0,
	-0.5, -0.5,   0.0,  0.0, 0.0,  0.0,  0.0, 1.0,
};



opengl_update_texture :: proc(pixels: []u8, width, height: i32, gl_ctx: ^GlContext, is_font: bool, channels: int, is_vert_flat: bool = true){
	using gl


	chn := u32(RGBA)
	if(channels == 3){
		chn = RGB
	}

	{
		Enable(BLEND);
		BindTexture(TEXTURE_2D, gl_ctx.tex_handle)

		if(is_font){
			PixelStorei(UNPACK_ALIGNMENT,1)
			BlendFunc(SRC_ALPHA, ONE_MINUS_SRC_ALPHA);  
			TexImage2D(TEXTURE_2D, 0, RED, width, height, 0, RED, UNSIGNED_BYTE, &pixels[0])
		}else{
			TexImage2D(TEXTURE_2D, 0, i32(chn), width, height, 0, chn, UNSIGNED_BYTE, &pixels[0])
		}


		TexParameteri(TEXTURE_2D, TEXTURE_MIN_FILTER, LINEAR_MIPMAP_LINEAR)
		TexParameteri(TEXTURE_2D, TEXTURE_MAG_FILTER, LINEAR)
		TexParameteri(TEXTURE_2D, TEXTURE_WRAP_S, MIRRORED_REPEAT)
		TexParameteri(TEXTURE_2D, TEXTURE_WRAP_T, MIRRORED_REPEAT)
		GenerateMipmap(TEXTURE_2D)
	}

	BindVertexArray(gl_ctx.vao)

	BindBuffer(ARRAY_BUFFER, gl_ctx.vbo)

	if(is_font){
		BufferData(ARRAY_BUFFER, len(vertices_flat) * size_of(f32), raw_data(vertices_font_straight), STATIC_DRAW)
	}
	else if(is_vert_flat){
		BufferData(ARRAY_BUFFER, len(vertices_flat) * size_of(f32), raw_data(vertices_flat), STATIC_DRAW)
	}else{
		BufferData(ARRAY_BUFFER, len(vertices_straight) * size_of(f32), raw_data(vertices_straight), STATIC_DRAW)
	}
	EnableVertexAttribArray(0)
	EnableVertexAttribArray(1)
	EnableVertexAttribArray(2)
	VertexAttribPointer(0, 3, FLOAT, TRUE, 8 * size_of(f32), uintptr(0))
	VertexAttribPointer(1, 2, FLOAT, TRUE, 8 * size_of(f32), (3 * size_of(f32)))
	VertexAttribPointer(2, 3, FLOAT, TRUE, 8 * size_of(f32), (5 * size_of(f32)))
}

/*
opengl_read_img_and_create_texure :: proc(){

	path :: "../data/lakhe/1.png"



	tex :TexHandle={} 
	tex.img, _ = png.load_from_bytes(#load(path))
	using gl
	using gl_conf

	UseProgram(gl_conf.program_id)
	Clear(COLOR_BUFFER_BIT | DEPTH_BUFFER_BIT)
	
	opengl_create_texture_from_img(&tex)
	//print(tex)


	ActiveTexture(TEXTURE0)
	BindBuffer(ARRAY_BUFFER, tex.gl.vbo)
	BindTexture(TEXTURE_2D, tex.gl.tex_handle)
	BindVertexArray(tex.gl.vao)


	//view := linalg.MATRIX4F32_IDENTITY
	proj := linalg.MATRIX4F32_IDENTITY

	scale := linalg.matrix4_scale_f32(vec3{2, 2, 2})
	transalation := linalg.matrix4_translate(vec3{0, 0, 0})
	view := linalg.MATRIX4F32_IDENTITY
	
	view *= scale


	model := linalg.MATRIX4F32_IDENTITY
	model = linalg.matrix4_translate(vec3{0, 0, 0})

	UniformMatrix4fv(uniforms["proj"].location, 1, FALSE,  &proj[0,0])
	UniformMatrix4fv(uniforms["view"].location, 1, FALSE , &view[0,0])
	UniformMatrix4fv(uniforms["model"].location, 1, FALSE, &model[0,0])
	Uniform1i(uniforms["is_tex"].location, 1)
	

	DrawArrays(TRIANGLES, 0, 6)
    glfw.SwapBuffers(state.window)

}
*/

opengl_create_texture :: proc(img :^TexHandle, width, height: i32, gl_ctx: ^GlContext, is_font: bool,  channels: int, is_vert_flat: bool = true){


	gl.GenVertexArrays(1, &gl_ctx.vao)
	gl.GenBuffers(1, &gl_ctx.vbo)

	chn := u32(gl.RGBA)
	if(channels == 3){
		chn = gl.RGB
	}

	{
		gl.GenTextures(1, &gl_ctx.tex_handle)

		gl.Enable(gl.BLEND);
		gl.BindTexture(gl.TEXTURE_2D, gl_ctx.tex_handle)

		if(is_font){
			gl.PixelStorei(gl.UNPACK_ALIGNMENT,1)
			gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);  
			gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RED, width, height, 0, gl.RED, gl.UNSIGNED_BYTE,raw_data(img.img.pixels.buf))
		}else{
			gl.TexImage2D(gl.TEXTURE_2D, 0, i32(chn), width, height, 0, chn, gl.UNSIGNED_BYTE, raw_data(img.img.pixels.buf))
		}


		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.MIRRORED_REPEAT)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.MIRRORED_REPEAT)
		gl.GenerateMipmap(gl.TEXTURE_2D)

	}

	gl.BindVertexArray(gl_ctx.vao)

	gl.BindBuffer(gl.ARRAY_BUFFER, gl_ctx.vbo)

	if(is_font){
		gl.BufferData(gl.ARRAY_BUFFER, len(vertices_flat) * size_of(f32), raw_data(vertices_font_straight), gl.STATIC_DRAW)
	}
	else if(is_vert_flat){
		gl.BufferData(gl.ARRAY_BUFFER, len(vertices_flat) * size_of(f32), raw_data(vertices_flat), gl.STATIC_DRAW)
	}else{
		gl.BufferData(gl.ARRAY_BUFFER, len(vertices_straight) * size_of(f32), raw_data(vertices_straight), gl.STATIC_DRAW)
	}
	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.EnableVertexAttribArray(2)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.TRUE, 8 * size_of(f32), uintptr(0)) 
	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.TRUE, 8 * size_of(f32), (3 * size_of(f32)))
	gl.VertexAttribPointer(2, 3, gl.FLOAT, gl.TRUE, 8 * size_of(f32), (5 * size_of(f32)))

}


opengl_create_texture_from_img :: proc(image : ^TexHandle){
	//context.allocator = platform.temp_allocator
	//context.temp_allocator = platform.temp_allocator

	opengl_create_texture(image, i32(image.img.width), i32(image.img.height), &image.gl,      false, image.img.channels, false)
	//opengl_create_texture(image, i32(image.img.width), i32(image.img.height), &image.gl_flat, false, image.img.channels,  true)

	free(image)

}
opengl_update_texture_from_img :: proc(image : ^TexHandle){
	//context.allocator = platform.temp_allocator
	//context.temp_allocator = platform.temp_allocator

	img_bytes := bytes.buffer_to_bytes(&image.img.pixels)

	//opengl_update_texture(img_bytes, i32(image.img.width), i32(image.img.height), &image.gl_flat,  false,  image.img.channels, true)
	opengl_update_texture(img_bytes, i32(image.img.width), i32(image.img.height), &image.gl,       false,  image.img.channels, false)
}









