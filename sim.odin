package doric
import "core:math/linalg"
import gl "vendor:OpenGL"

mat3 :: linalg.Matrix3x2f32
mat2 :: linalg.Matrix2x2f32

/*
  Simulation is just steps to prepare entities to simulate

  Before moving the entities and running the game code to change entities
  We need to select the entities that are in the bounds of our screen 
  Calculate the position of the entities relative to the center of the simulation
  Add the entities to a structure array 
*/

/*


  Usecase 

  begin_sim(center, bounds, entities) -> SimRegion

  movement code

  render_entities(sim_region)
  end_sim(sim_region)
*/

//This is the entity struct that we use for simulating i.e movements
SimEntity :: struct {
    pos, dp   : vec2,
    index     : EntityIndex,
}



SimRegion :: struct {
    entity_count : u32,
    entities : [1000]SimEntity, 
    bounds   : mat2,
    center   : WorldPos,
}

add_entity_to_sim :: proc(
    //game_state: ^GameState,
    region:    ^SimRegion,
    low_index:  EntityIndex,
    low:       ^Entity,
    entity_rel_pos: vec2,
) -> ^SimEntity {
    context.allocator      = state.allocator
    context.temp_allocator = state.temp_allocator

    //context.allocator = platform.temp_allocator
    assert(low_index != 0)

    entity := &region.entities[region.entity_count]

    assert(low != nil) //?

    //entity^ = low
    //low.flags += {.entity_flag_simming, }

    entity.index = low_index
    entity.pos   = entity_rel_pos
    entity.dp    = low.dp 
    region.entity_count += 1

    //append(&region.entities, entity)

    return entity
}

//Finds the entities that are in the simulation
//Calculates the position of the entities relative to the center of the simulation
//Adds the entities inside the bounds to the entities array of the sim region

begin_sim :: proc(center : WorldPos, bounds : mat2) -> ^SimRegion{
    context.allocator      = state.temp_allocator
    context.temp_allocator = state.temp_allocator

    world := &state.world

    sim_region := new(SimRegion)
    sim_region.center = center
    sim_region.bounds = bounds
    sim_region.entity_count = 0;

    min_chunk_pos := map_into_world_pos(sim_region.center, vec2(bounds[0])).chunk
    max_chunk_pos := map_into_world_pos(sim_region.center, vec2(bounds[1])).chunk

    //go thru all the chunks that is covered by the bounds
    for x in min_chunk_pos.x ..= max_chunk_pos.x {
	for y in min_chunk_pos.y ..= max_chunk_pos.y{


	    chunk := get_world_chunk(vec2i{i32(x), i32(y)})

	    if chunk != nil{

		for item, index in chunk.entities{
		    entity := state.game.entities[u32(item)]
		    if(entity.type != .None){
			entity_sim_space  := subtract(entity.wpos, sim_region.center)
			add_entity_to_sim(sim_region, item, &entity, entity_sim_space)
		    }
		}
	    }
	}
    }

    return sim_region
}



/*
  To end the simulation we just go thru all the entities that was in the simulation
  We convert the vec3 position of the entity in the simulation to the WorldPos and store to the 
  Main entities array of the GameState

 Instead of doing in manually we call the function change_entitty_location from world.odin because we also need to see if the entity has changed the chunk while moving
*/
end_sim :: proc(region: ^SimRegion){

    for entity, i in region.entities{

	if i >= int(region.entity_count) do break

	low := &state.game.entities[u32(entity.index)]

	//flag stuffs

	new_world_pos := map_into_world_pos(region.center, entity.pos)
	old_pos := low.wpos

	if old_pos.chunk != new_world_pos.chunk || old_pos.offset != new_world_pos.offset{
	    change_entity_location(entity.index, low, new_world_pos)
	}
    }
}

render_entities :: proc(region: ^SimRegion)
{
    using gl

    context.allocator      = state.allocator
    context.temp_allocator = state.temp_allocator
    UseProgram(state.program_id)
    ActiveTexture(TEXTURE0)

    proj, view : linalg.Matrix4f32
    Uniform1i(state.uniforms["is_tex"].location, 1)

    translation := linalg.matrix4_translate_f32({0,0, 0})
    scale := linalg.matrix4_scale(vec3{1,1,1})
    view = translation * scale
    proj = linalg.MATRIX4F32_IDENTITY

    Uniform1i(state.uniforms["light_on"].location, 0)

    UniformMatrix4fv(state.uniforms["proj"].location, 1, FALSE,  &proj[0,0])
    UniformMatrix4fv(state.uniforms["view"].location, 1, FALSE , &view[0,0])

    for entity, i in region.entities
    {

	if i >= int(region.entity_count) do break
	low := state.game.entities[u32(entity.index)]

	asset := get_asset(low.asset_id)
	gl_ctx := &asset.textures[0].gl

	BindBuffer(ARRAY_BUFFER, gl_ctx.vbo)
	BindTexture(TEXTURE_2D, gl_ctx.tex_handle)
	BindVertexArray(gl_ctx.vao)

	model     := linalg.matrix4_translate(vec3{entity.pos.x, entity.pos.y, 0})
	new_scale := vec3{low.scale.x, low.scale.y, 1}
	entity_scale := linalg.matrix4_scale(new_scale)
	model *= entity_scale

	UniformMatrix4fv(state.uniforms["model"].location, 1, FALSE, &model[0,0])
	DrawArrays(TRIANGLES, 0, 6)
    }
}










