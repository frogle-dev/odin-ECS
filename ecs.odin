package main

// import "core:fmt"

import "ecs"

Entity :: u32

Entity_Location :: struct {
	archetype: Archetype,
	idx:       uint,
}

World :: struct {
	a_player:              #soa[dynamic]Player,
	a_enemy:               #soa[dynamic]Enemy,
	a_ball:                #soa[dynamic]Ball,
	a_physics_square:      #soa[dynamic]Physics_Square,
	a_ui:                  #soa[dynamic]Ui,
	entity_locations:      map[Entity]Entity_Location,
	next_available_entity: Entity,
}

init :: proc(world: ^World, allocator := context.allocator) -> ecs.Error {
	world.a_player = make(#soa[dynamic]Player, allocator) or_return

	world.a_enemy = make(#soa[dynamic]Enemy, allocator) or_return

	world.a_ball = make(#soa[dynamic]Ball, allocator) or_return

	world.a_physics_square = make(#soa[dynamic]Physics_Square, allocator) or_return

	world.a_ui = make(#soa[dynamic]Ui, allocator) or_return

	world.entity_locations = make(map[Entity]Entity_Location, allocator)

	world.next_available_entity = 0

	return {}
}

deinit :: proc(world: ^World) {
	delete(world.a_player)
	delete(world.a_ball)
	delete(world.a_physics_square)
	delete(world.a_ui)
	delete(world.entity_locations)
}

spawn :: proc(world: ^World, archetype: Archetype) -> (Entity, bool) {
	switch a in archetype {
	case Player:
		append(&world.a_player, a)

		world.entity_locations[world.next_available_entity] = {
			archetype = a,
			idx       = len(world.a_player),
		}
	case Enemy:
	case Ball:
	case Physics_Square:
	case Ui:
	}

	world.next_available_entity += 1

	return 0, false
}
