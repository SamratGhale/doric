Doric is a concept for my game development libarary
It's my attempt to bring together the algorithms and snippets of code to be used as a library

usage code

compile using the following command to run the test program

odin run . -define:TEST_DORIC=true

```odin
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

	for &entity in &sim_region.entities{
	    low := state.game.entities[u32(entity.index)]

	    #partial switch low.type{
	    case .Player:{
		if is_down(.MOVE_DOWN){
		    entity.pos.y -= 0.01
		    //TOOD: the library should give some prebuilt functions to move player
		}
		if is_down(.MOVE_UP){
		    entity.pos.y += 0.01
		}
	    }
	    }
	}


	end_sim(sim_region)
	EndFrame()
    }

}