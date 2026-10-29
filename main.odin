package main

import "core:fmt"
import "core:log"
import "core:mem"
import "core:testing"

import "ecs"

check :: proc(err: ecs.Error, msg := #caller_expression) {
	if err != nil {
		fmt.panicf("%s: %s", msg, ecs.error_string(err))
	}
}

main :: proc() {
	context.logger = log.create_console_logger()
	defer log.destroy_console_logger(context.logger)

	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				log.errorf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					log.errorf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				log.errorf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					log.errorf("- %p @ %v\n", entry.memory, entry.location)
				}
			}

			mem.tracking_allocator_destroy(&track)
		}
	}

	check(ecs.generate("data.odin"))
}

@(test)
spawning :: proc(t: ^testing.T) {
	world: World
	defer destroy_world(&world)

	for i in 0 ..< 1000 {
		f := f32(i)

		_, err := spawn(
			&world,
			Player {
				pos = {x = f, y = f},
				vel = {x = f, y = f},
				acc = {x = f, y = f},
				hp = {f},
				atk = {f},
				sta = {f},
				mana = {f},
				tag = {},
			},
		)
		check(err)

		_, err = spawn(
			&world,
			Enemy {
				pos = {x = f, y = f},
				vel = {x = f, y = f},
				acc = {x = f, y = f},
				hp = {f},
				atk = {f},
				sta = {f},
				tag = {},
			},
		)
		check(err)

		_, err = spawn(&world, Ball{pos = {x = f, y = f}, vel = {x = f, y = f}})
		check(err)

		_, err = spawn(
			&world,
			Physics_Square{pos = {x = f, y = f}, vel = {x = f, y = f}, acc = {x = f, y = f}},
		)
		check(err)

		_, err = spawn(&world, Ui{pos = {x = f, y = f}})
		check(err)

		testing.expect(t, len(world.a_player.data) == len(world.a_player.entities))
		testing.expect(t, len(world.a_enemy.data) == len(world.a_enemy.entities))
		testing.expect(t, len(world.a_ball.data) == len(world.a_ball.entities))
		testing.expect(t, len(world.a_physics_square.data) == len(world.a_physics_square.entities))
		testing.expect(t, len(world.a_ui.data) == len(world.a_ui.entities))
	}
}
