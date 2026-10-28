package main

import "core:fmt"
import "core:log"
import "core:mem"

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

	world: World
	defer destroy_world(&world)

	_, err := spawn(
		&world,
		Physics_Square{pos = {x = 5, y = 6}, vel = {x = 2, y = 5}, acc = {x = 10, y = 2}},
	)
	check(err)
}
