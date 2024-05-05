package doric

import im "./odin-imgui"
import "core:mem/virtual"
import "base:runtime"
import "core:math/linalg"

/** The world defines and implements the coordinate system for the game
 * It is grid based system where the world includes many chunks in 2d or 3d space
 * Each chunk has it's own point of origin and coordinate system
 * and the chunk has entities inside it
 * Each entity has a world position which says which chunk it is in and which
 * coordinate inside the chunk it is in
 **/


TILE_CHUNK_UNINITILIZED :: 2147483647
TILE_COUNT_PER_WIDTH    :: 10
TILE_COUNT_PER_HEIGHT   :: 10

WorldPos :: struct{
    chunk : vec2i, //for 2d world
    offset: vec2
}

Chunk :: struct {
    pos : vec2i,
    entities : [dynamic]EntityIndex,
}

World :: struct {
    csim : vec2,
    chunk_hash : map[i32][dynamic]Chunk,
    meters_to_pixels: u32,

    center : WorldPos,
    bounds : mat2,
    scale  : vec3, //Vec3 because we also want to control how big is our z axis
}

add_new_chunk :: proc(pos: vec2i){

    new_chunk : Chunk 
    new_chunk.pos = pos

    hash := 19 * abs(pos.x) + 7 + abs(pos.y)
    world := &state.world

    if world.chunk_hash[hash] == nil{
        world.chunk_hash[hash] = make([dynamic]Chunk)
    }

    head_chunk := &world.chunk_hash[hash]
    append(head_chunk, new_chunk)
}

get_world_chunk :: proc(pos: vec2i)->^Chunk{
    context.allocator      = state.allocator
    context.temp_allocator = state.temp_allocator
    hash := 19 * abs(pos.x) + 7 + abs(pos.y)

    world := &state.world

    head_chunk := &world.chunk_hash[hash]

    if head_chunk == nil{
	world.chunk_hash[hash] = make([dynamic]Chunk)
    }
    head_chunk = &world.chunk_hash[hash]

    found_chunk : ^Chunk = nil

    for &chunk in head_chunk{
	if chunk.pos == pos{
	    found_chunk = &chunk
	}
    }
    if found_chunk == nil{
	new_chunk :Chunk= {}
	new_chunk.pos = pos
	append(head_chunk, new_chunk)


	for &chunk in head_chunk{

	    if chunk.pos == pos{
		found_chunk = &chunk
	    }
	}
    }

    return found_chunk
}

change_entity_index :: proc(pos: WorldPos, old_index, new_index : EntityIndex){
    if old_index == 0 || new_index == 0 do return;

    chunk := get_world_chunk(pos.chunk)
    assert(chunk != nil)
    found := false

    for item, index in chunk.entities{
        if item == old_index{
            unordered_remove(&chunk.entities, index)
            append(&chunk.entities, new_index)
            found = true
            break
        }
    }
    assert(found)
}

remove_entity_from_world :: proc(old_p: WorldPos, entity_index: EntityIndex){
    if entity_index == 0 do return;
    chunk := get_world_chunk(old_p.chunk)
    assert(chunk != nil)
    found := false

    for item, index in chunk.entities{
        if item == entity_index{
            unordered_remove(&chunk.entities, index)
            //append(&chunk.entities, new_index)
            found = true
            break
        }
    }
    assert(found)
}

change_entity_location :: proc(entity_index:EntityIndex, entity: ^Entity, new_p: WorldPos){
    //Remove old entity from the chunk
    //Add new entity to new chunk
    context.allocator      = state.allocator
    context.temp_allocator = state.temp_allocator

    if entity_index == 0 do return

        old_p := entity.wpos

        if new_p.chunk.x != TILE_CHUNK_UNINITILIZED{
            //remove from old chunk
            if old_p.chunk.x != TILE_CHUNK_UNINITILIZED{
                chunk := get_world_chunk(old_p.chunk)
                assert(chunk != nil)

                if new_p.chunk != old_p.chunk{
                    for item, index in chunk.entities{
                        if entity_index == item {
                            unordered_remove(&chunk.entities, index)
                        }
                    }
                }
            }

            //add to new chunk
            if new_p.chunk != old_p.chunk{
                chunk := get_world_chunk(new_p.chunk)
                found := false

                //check of the item already exists in the chunk
                for item in chunk.entities{
                    if item == entity_index{
                        found = true
                        break
                    }
                }

                //Add if the entity is not in the chunk
                if !found{
                    append(&chunk.entities, entity_index)
                }
            }
            entity.wpos = new_p
        }
}

//Initilize the chunk size in meter etc.
initilize_world :: proc()
{

    world := &state.world
    world.chunk_hash = make_map(map[i32][dynamic]Chunk)
    world.csim = vec2{f32(TILE_COUNT_PER_WIDTH), f32(TILE_COUNT_PER_HEIGHT)}
    world.scale = {1,1,1}

    //All chunks are uninitilize at first
    for key, &chunk in world.chunk_hash
    {
        chunk = {}
        chunk[0].pos.x  = TILE_CHUNK_UNINITILIZED
    }
}

//sometimes the offset is greater than csim while simulating
//This function adjusts the position
adjust_world_position :: proc(
    chunk_pos: ^i32,
    offset   : ^f32,
    csim     :  f32,
){
    extra_offset : i32 = i32(linalg.floor( offset^ / csim))
    chunk_pos^  += extra_offset
    offset^     -= f32( f32(extra_offset) * csim)
}


/*
 * This function adds the offset to a world position
 */
map_into_world_pos :: proc( origin: WorldPos, offset: vec2 ) -> WorldPos
{
    csim := state.world.csim

    result := origin

    result.offset += offset

    adjust_world_position(&result.chunk.x, &result.offset.x, csim.x)
    adjust_world_position(&result.chunk.y, &result.offset.y, csim.y)
    return result
}

/*
 * Gives the diffirence between two world pos in vec2
 */
subtract :: proc(a: WorldPos, b : WorldPos) -> vec2
{
    result : vec2
    result.y = f32(a.chunk.y - b.chunk.y)
    result.x = f32(a.chunk.x - b.chunk.x)
    result *= state.world.csim
    result += (a.offset - b.offset)
    return result
}





/*
    This imgui panel should allow for inspectaion and manipulation of the world parameters

    Control where the center of the world is
    Control world bounds 
*/
render_world_panel :: proc(){
    world := &state.world
    if im.Begin("World"){
	im.Text("Hello world")
	im.SliderInt("chunk_x", &world.center.chunk.x, -20, 20)
	im.SliderInt("chunk_y", &world.center.chunk.y, -20, 20)
	im.SliderFloat("offset_x", &world.center.offset.x, -10, 10)
	im.SliderFloat("offset_y", &world.center.offset.y, -10, 10)

	im.Text("Camera bounds")
	im.SliderFloat("bound_neg_x", &world.bounds[0,0], -20, 20)
	im.SliderFloat("bound_pos_x", &world.bounds[0,1], -20, 20)
	im.SliderFloat("bound_neg_y", &world.bounds[1,0], -20, 20)
	im.SliderFloat("bound_pos_y", &world.bounds[1,1], -20, 20)

	im.Text("World scale")
	im.SliderFloat("scale_x", &world.scale.x, -20, 20)
	im.SliderFloat("scale_y", &world.scale.y, -20, 20)
	im.SliderFloat("scale_z", &world.scale.z, 0, 1)
    }
    im.End()
}





















