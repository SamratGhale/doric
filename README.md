Doric is a concept for my game development libarary
It's my attempt to bring together the algorithms and snippets of code to be used as a library

usage code

compile using the following command to run the test program

odin run . -define:TEST_DORIC=true

```odin

main :: proc (){

    dr_state : DoricState

    Init(&dr_state, 900, 900, "Hello", .GLFW)

    add_entity({chunk  = { 0,0}, offset = {0,0}},  .Wall, "wall_rough")
    add_entity({chunk  = { 0,0}, offset = {1,0}},  .Wall, "wall_rough")
    add_entity({chunk  = { 0,0}, offset = {-1,0}}, .Wall, "wall_rough")

    for dr_state.running{
	StartFrame()
	sim_region := begin_sim(state.world.center, state.world.bounds)

	for &entity in &sim_region.entities{
	    if is_down(.MOVE_DOWN){
		entity.pos.y -= 0.01
	    }
	}


	end_sim(sim_region)
	EndFrame()
    }

}