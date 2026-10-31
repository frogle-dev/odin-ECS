package main

import "core:testing"

import "ecs"

Entity :: uint

Entity_Location :: struct {
	// TODO: potentially change archetype field because it shouldnt hold any data
	archetype: Archetype,
	idx:       uint,
}

Internal_Archetype :: struct($User_Archetype: typeid) {
	// TODO: add a check that ensures User_Archetype is of Archetype union
	data:     #soa[dynamic]User_Archetype,
	entities: [dynamic]Entity,
}

delete_internal_archetype :: proc(a: Internal_Archetype($User_Archetype)) -> ecs.Error {
	delete(a.data) or_return
	delete(a.entities) or_return

	return nil
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

destroy_world :: proc(world: ^World) {
	delete_internal_archetype(world.a_player)

	delete_internal_archetype(world.a_enemy)

	delete_internal_archetype(world.a_ball)

	delete_internal_archetype(world.a_physics_square)

	delete_internal_archetype(world.a_ui)

	delete(world.entity_locations)
}

// TODO: use this function in places that need it
get_archetype_field :: proc(world: ^World, $T: typeid) -> ^Internal_Archetype(T) {
	when T == Player do return world.a_player
	else when T == Enemy do return world.a_enemy
	else when T == Ball do return world.a_ball
	else when T == Physics_Square do return world.a_physics_square
	else when T == Ui do return world.a_player

	return nil
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
		world.entity_locations[archetype.entities[len(archetype.entities) - 1]].idx ==
		len(archetype.entities) - 1,
	)

	return nil
}

spawn :: proc(world: ^World, archetype: Archetype) -> (entity: Entity, err: ecs.Error) {
	switch a in archetype {
	case Player:
		append_entity_data(world, &world.a_player, a) or_return
	case Enemy:
		append_entity_data(world, &world.a_enemy, a) or_return
	case Ball:
		append_entity_data(world, &world.a_ball, a) or_return
	case Physics_Square:
		append_entity_data(world, &world.a_physics_square, a) or_return
	case Ui:
		append_entity_data(world, &world.a_ui, a) or_return
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

//////////// CHECKS FOR TESTING ///////////////

archetype_checks :: proc(
	t: ^testing.T,
	world: ^World,
	a: ^Internal_Archetype($T),
	expected_data: []T,
) {
	testing.expect(t, len(a.data) == len(a.entities))

	for e, i in a.entities {
		_, ok := world.entity_locations[e].archetype.(T)
		testing.expect(t, ok)

		testing.expect(t, a.entities[world.entity_locations[e].idx] == e)

		verify_data(t, world, e, a, &expected_data[i])
	}
}

Verify_Info :: struct {
	player_expected:         [dynamic]Player,
	enemy_expected:          [dynamic]Enemy,
	ball_expected:           [dynamic]Ball,
	physics_square_expected: [dynamic]Physics_Square,
	ui_expected:             [dynamic]Ui,
}

destroy_verify :: proc(info: ^Verify_Info) {
	delete(info.player_expected)
	delete(info.enemy_expected)
	delete(info.ball_expected)
	delete(info.physics_square_expected)
	delete(info.ui_expected)
}

verify :: proc(t: ^testing.T, world: ^World, info: Verify_Info) {
	archetype_checks(t, world, &world.a_player, info.player_expected[:])
	archetype_checks(t, world, &world.a_enemy, info.enemy_expected[:])
	archetype_checks(t, world, &world.a_ball, info.ball_expected[:])
	archetype_checks(t, world, &world.a_physics_square, info.physics_square_expected[:])
	archetype_checks(t, world, &world.a_ui, info.ui_expected[:])
}

verify_data :: proc(
	t: ^testing.T,
	world: ^World,
	e: Entity,
	a: ^Internal_Archetype($T),
	data: ^T,
) {
	i := world.entity_locations[e].idx

	testing.expect(t, a.data[i] == data^)
	testing.expect(t, a.entities[i] == e)
}
