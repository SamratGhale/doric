package doric

/*
  How should entity system work?


  The movement and behaviours of the entities should be defined by the game designer 
  Provide some default movements like do nothing or move in some direction?
  Let's not worry about movement for now
*/

//The first eneity in the entities of the gamestate should be a None entity
//Maybe do it as part of the doric initilization
//TODO: Game designer should be able to define the entity types


//Entity base
//For testing purposes for now
EntityType :: enum{None, Player, Gravity, Stone, Wall, Gate }
Entity :: struct{
    //pos           : vec2,
    wpos          : WorldPos,
    scale         : vec2,
    collides      : b32,
    is_gravity    : b32,
    tex           : ^TexHandle,
    varient       : uintptr, // For a entity of type player this is the pointer to the Player struct 
    type          : EntityType,
    dp            : vec2,
    index         : EntityIndex,
    asset_id      : string,
}



add_entity :: proc(pos: WorldPos, type: EntityType, asset_id : string) -> ^Entity
{
    uninitwpos := WorldPos{chunk={TILE_CHUNK_UNINITILIZED, TILE_CHUNK_UNINITILIZED}}
    entity : Entity = {type = type, wpos = uninitwpos, scale = {1,1}, asset_id = asset_id, index = EntityIndex(len(state.game.entities))}

    //for now just use the same texture for everyone

    append(&state.game.entities, entity)

    new_entity := &state.game.entities[len(state.game.entities) -1 ]
    change_entity_location(entity.index, new_entity, pos)
    return new_entity
}
