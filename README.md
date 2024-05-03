Doric is a concept for my game development libarary
It's my attempt to bring together the algorithms and snippets of code to be used as a library

usuage code

compile using the following command to run the test program

odin run . -define:TEST_DORIC=true

```odin
main :: proc (){

    dr_state : DoricState

    Init(&dr_state, 900, 900, "Hello", .GLFW)

    add_entity({chunk  = { 0,0}, offset = {0,0}}, .Player, "wall_rough")
    for dr_state.running{
	StartFrame()

	EndFrame()
    }
}
