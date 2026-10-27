package main

import "ecs"

Entity :: u32

A_player :: struct {
	entity: Entity,
	_:      Position,
	_:      Velocity,
	_:      Acceleration,
	_:      Health,
	_:      Attack,
	_:      Stamina,
	_:      Mana,
	_:      PlayerTag,
}

A_enemy :: struct {
	entity: Entity,
	_:      Position,
	_:      Velocity,
	_:      Acceleration,
	_:      Health,
	_:      Attack,
	_:      Stamina,
	_:      EnemyTag,
}

A_ball :: struct {
	entity: Entity,
	_:      Position,
	_:      Velocity,
}

A_physics_square :: struct {
	entity: Entity,
	_:      Position,
	_:      Velocity,
	_:      Acceleration,
}

A_ui :: struct {
	entity: Entity,
	_:      Position,
}

Archetype_Id :: enum {
	Player,
	Enemy,
	Ball,
	Physics_Square,
	Ui,
}

Entity_Location :: struct {
	archetype_id: Archetype_Id,
	idx:          uint,
}

World :: struct {
	a_player:         #soa[dynamic]A_player,
	a_enemy:          #soa[dynamic]A_enemy,
	a_ball:           #soa[dynamic]A_ball,
	a_physics_square: #soa[dynamic]A_physics_square,
	a_ui:             #soa[dynamic]A_ui,
	entity_locations: map[Entity]Entity_Location,
}

init :: proc(world: ^World, allocator := context.allocator) -> ecs.Error {
	world.a_player = make(#soa[dynamic]A_player, allocator) or_return
	world.a_enemy = make(#soa[dynamic]A_enemy, allocator) or_return
	world.a_ball = make(#soa[dynamic]A_ball, allocator) or_return
	world.a_physics_square = make(#soa[dynamic]A_physics_square, allocator) or_return
	world.a_ui = make(#soa[dynamic]A_ui, allocator) or_return
	world.entity_locations = make(map[Entity]Entity_Location, allocator)

	return {}
}
