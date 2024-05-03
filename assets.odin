package doric

import "core:os"
import "core:image/png"
import "core:thread"
import "core:mem/virtual"
import "core:strings"
import "core:encoding/json"
import "core:image"
import "core:fmt"

/*
For now this is just copied from sattal singh game
Parsing the assets also happens at the initilization phase
The user should be able to edit and provide the json file
TODO: 
1. Use animation editor to pack the textures and the assets.odin should user it instead
*/

TexBundle :: struct {
	textures: [dynamic]^TexHandle,
}

Asset :: struct{
	assets : map[string]^TexBundle,
}

ArtFileThreadArg :: struct {
	path : string,
	tex  : ^TexHandle,
}

asset_thread :: proc (task : thread.Task){
	//context.allocator = platform.temp_allocator
	arg := cast(^ArtFileThreadArg)task.data

	err : png.Error
	arg.tex.img, err = png.load_from_file(arg.path)
	if err != image.PNG_Error.None{
		fmt.println(arg.path)
	}

}

parse_all_asset_end :: proc(){
	fmt.println("Finish setting up the pool")
	pool := &state.pool
	assets := &state.asset.assets

	thread.pool_finish(pool)
	thread.pool_destroy(pool)

	for key, val in assets{
		for tex in val.textures{
			opengl_create_texture_from_img(tex)
		}
	}
	//virtual.arena_free_all(&platform.temp_arena)
    fmt.println("Finished creating texture")
}

parse_all_asset_start :: proc(){

    //read the assets.json file and parse it 
    //context.allocator = platform.allocator


    data, success := os.read_entire_file("assets.json")

    if success{
	state.asset = new(Asset)

	state.asset.assets = make(map[string]^TexBundle, 100)
	assets := &state.asset.assets

	parsed_map, _ := json.parse(data, .MJSON)


	err : png.Error

	pool := &state.pool

	thread.pool_init(pool, allocator = context.allocator, thread_count = 8)

	for item in parsed_map.(json.Array){
	    for key, value in item.(json.Object){

		assets[key] = new(TexBundle)
		key_tex := assets[key]
		key_tex.textures =  make([dynamic]^TexHandle,0, len(value.(json.Array)))

		for file_name in value.(json.Array){
		    new_tex := new(TexHandle)
		    formatted_path := fmt.aprintf("test_data/{}", file_name)

		    data      := new(ArtFileThreadArg)
		    data.tex   = new_tex
		    data.path  = formatted_path

		    thread.pool_add_task(pool, allocator = context.allocator, procedure = asset_thread, data = rawptr(data), user_index = 1)

		    append(&key_tex.textures, new_tex)

		}
	    }
	}
	thread.pool_start(pool)
    }
}

get_asset :: proc(asset_id : string)-> ^TexBundle{
	//context.allocator = platform.temp_allocator
	assets := &state.asset.assets
	asset := assets[asset_id]
	return asset
}









