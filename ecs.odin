package main

// import "core:fmt"

import "ecs"

Entity :: uint

Entity_Location :: struct {
	archetype: Archetype,
	idx:       uint,
}

Internal_Archetype :: struct($User_Archetype: typeid) {
	data:     #soa[dynamic]User_Archetype,
	entities: [dynamic]Entity,
}

World :: struct {
	a_player:         Internal_Archetype(Player),
	a_enemy:          Internal_Archetype(Enemy),
	a_ball:           Internal_Archetype(Ball),
	a_physics_square: Internal_Archetype(Physics_Square),
	a_ui:             Internal_Archetype(Ui),

	entity_locations:      map[Entity]Entity_Location,
	next_available_entity: Entity,
}

delete_internal_archetype :: proc(a: Internal_Archetype($User_Archetype)) -> ecs.Error {
	delete(a.data) or_return
	delete(a.entities) or_return

	return nil
}

destroy_world :: proc(world: ^World) {
	delete_internal_archetype(world.a_player)

	delete_internal_archetype(world.a_enemy)

	delete_internal_archetype(world.a_ball)

	delete_internal_archetype(world.a_physics_square)

	delete_internal_archetype(world.a_ui)

	delete(world.entity_locations)
}

append_entity_data :: proc(
	world: ^World,
	archetype: ^Internal_Archetype($User_Archetype),
	data: User_Archetype,
) -> ecs.Error {
	world.entity_locations[world.next_available_entity] = {
		archetype = data,
		idx       = len(archetype.data),
	}

	append(&archetype.data, data) or_return
	append(&archetype.entities, world.next_available_entity) or_return

	assert(
		world.entity_locations[world.next_available_entity].idx ==
		archetype.entities[len(archetype.entities) - 1],
	)

	return nil
}

spawn :: proc(world: ^World, archetype: Archetype) -> (entity: Entity, err: ecs.Error) {
	switch a in archetype {
	case Player:
		append_entity_data(world, &world.a_player, a) or_return

	// assert(len(world.a_player) == len(world.player_entities))
	case Enemy:
		append_entity_data(world, &world.a_enemy, a) or_return

	// assert(len(world.a_enemy) == len(world.enemy_entities))
	case Ball:
		append_entity_data(world, &world.a_ball, a) or_return

	// assert(len(world.a_ball) == len(world.ball_entities))
	case Physics_Square:
		append_entity_data(world, &world.a_physics_square, a) or_return

	// assert(len(world.a_physics_square) == len(world.physics_square_entities))
	case Ui:
		append_entity_data(world, &world.a_ui, a) or_return

	// assert(len(world.a_ui) == len(world.ui_entities))
	}

	entity = world.next_available_entity
	world.next_available_entity += 1

	err = nil
	return
}

swap_and_pop :: proc(
	world: ^World,
	archetype: ^Internal_Archetype($User_Archetype),
	entity: Entity,
	swap_loc: Entity_Location,
) -> ecs.Error {
	last_idx := len(archetype.data) - 1

	// swap
	archetype.data[swap_loc.idx] = archetype.data[last_idx]
	archetype.entities[swap_loc.idx] = archetype.entities[last_idx]

	world.entity_locations[archetype.entities[swap_loc.idx]] = swap_loc

	// remove entity from entity locations hashmap
	delete_key(&world.entity_locations, entity)

	// even though these return allocator error, they shouldnt fail because the size of the arrays are never increased, only decreased
	err := resize(&archetype.data, last_idx)
	assert(err == nil)

	err = resize(&archetype.entities, last_idx)
	assert(err == nil)

	assert(!(entity in world.entity_locations))
	assert(len(archetype.data) == len(archetype.entities))

	assert(
		(len(archetype.data) == 0) ||
		(world.entity_locations[archetype.entities[swap_loc.idx]].idx == swap_loc.idx),
	)

	return nil
}

despawn :: proc(world: ^World, entity: Entity) -> ecs.Error {
	loc := world.entity_locations[entity]

	// despawn '4': swap the last element into the spot that is being despawned
	// 123456789
	//    ^
	// 12395678
	//    ^ swap 9 into 4's spot, decrement the size of the dynamic array

	switch a in loc.archetype {
	case Player:
		swap_and_pop(world, &world.a_player, entity, loc) or_return
	case Enemy:
		swap_and_pop(world, &world.a_enemy, entity, loc) or_return
	case Ball:
		swap_and_pop(world, &world.a_ball, entity, loc) or_return
	case Physics_Square:
		swap_and_pop(world, &world.a_physics_square, entity, loc) or_return
	case Ui:
		swap_and_pop(world, &world.a_ui, entity, loc) or_return
	}

	return nil
}
