package main

// import "core:fmt"

import "ecs"

Entity :: uint

Entity_Location :: struct {
	archetype: Archetype,
	idx:       uint,
}

World :: struct {
	a_player:        #soa[dynamic]Player,
	player_entities: [dynamic]Entity,

	a_enemy:        #soa[dynamic]Enemy,
	enemy_entities: [dynamic]Entity,

	a_ball:        #soa[dynamic]Ball,
	ball_entities: [dynamic]Entity,

	a_physics_square:        #soa[dynamic]Physics_Square,
	physics_square_entities: [dynamic]Entity,

	a_ui:        #soa[dynamic]Ui,
	ui_entities: [dynamic]Entity,

	entity_locations:      map[Entity]Entity_Location,
	next_available_entity: Entity,
}

destroy_world :: proc(world: ^World) {
	delete(world.a_player)
	delete(world.player_entities)

	delete(world.a_enemy)
	delete(world.enemy_entities)

	delete(world.a_ball)
	delete(world.ball_entities)

	delete(world.a_physics_square)
	delete(world.physics_square_entities)

	delete(world.a_ui)
	delete(world.ui_entities)

	delete(world.entity_locations)
}

append_entity_data :: proc(
	world: ^World,
	archetype_arr: ^$T/#soa[dynamic]$E,
	entity_arr: ^[dynamic]Entity,
	data: E,
) -> ecs.Error {
	world.entity_locations[world.next_available_entity] = {
		archetype = data,
		idx       = len(archetype_arr^),
	}

	append(archetype_arr, data) or_return
	append(entity_arr, world.next_available_entity) or_return

	assert(
		world.entity_locations[world.next_available_entity].idx == entity_arr[len(entity_arr) - 1],
	)

	return nil
}

spawn :: proc(world: ^World, archetype: Archetype) -> (entity: Entity, err: ecs.Error) {
	switch a in archetype {
	case Player:
		append_entity_data(world, &world.a_player, &world.player_entities, a) or_return

		assert(len(world.a_player) == len(world.player_entities))
	case Enemy:
		append_entity_data(world, &world.a_enemy, &world.enemy_entities, a) or_return

		assert(len(world.a_enemy) == len(world.enemy_entities))
	case Ball:
		append_entity_data(world, &world.a_ball, &world.ball_entities, a) or_return

		assert(len(world.a_ball) == len(world.ball_entities))
	case Physics_Square:
		append_entity_data(
			world,
			&world.a_physics_square,
			&world.physics_square_entities,
			a,
		) or_return

		assert(len(world.a_physics_square) == len(world.physics_square_entities))
	case Ui:
		append_entity_data(world, &world.a_ui, &world.ui_entities, a) or_return

		assert(len(world.a_ui) == len(world.ui_entities))
	}

	entity = world.next_available_entity
	world.next_available_entity += 1

	err = nil
	return
}

despawn :: proc(world: ^World, entity: Entity) {
	loc := world.entity_locations[entity]

	// despawn '4': swap the last element into the spot that is being despawned
	// 123456789
	//    ^
	// 12395678
	//    ^ swap 9 into 4's spot, decrement the size of the dynamic array

	switch a in loc.archetype {
	case Player:
	// assert(

	case Enemy:
	case Ball:
	case Physics_Square:
		last_idx := len(world.a_physics_square) - 1

		// swap
		world.a_physics_square[loc.idx] = world.a_physics_square[last_idx]
		world.physics_square_entities[loc.idx] = world.physics_square_entities[last_idx]

		world.entity_locations[world.physics_square_entities[loc.idx]] = loc

		// remove entity from entity locations hashmap
		delete_key(&world.entity_locations, entity)

		resize(&world.a_physics_square, last_idx)
		resize(&world.physics_square_entities, last_idx)

		assert(!(entity in world.entity_locations))
		assert(len(world.a_physics_square) == len(world.physics_square_entities))

		assert(
			(len(world.a_physics_square) == 0) ||
			(world.entity_locations[world.physics_square_entities[loc.idx]].idx == loc.idx),
		)

	case Ui:
	}
}
