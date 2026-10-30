package main

import "core:fmt"
import "core:log"
import "core:math/rand"
import "core:testing"
import "core:time"

import "ecs"

check :: proc(err: ecs.Error, msg := #caller_expression) {
	if err != nil {
		fmt.panicf("%s: %s", msg, ecs.error_string(err))
	}
}

spawn_w_verify_info :: proc(
	world: ^World,
	data: Archetype,
	info: ^Verify_Info,
	total_spawn_time: ^time.Duration,
) {
	start := time.tick_now()

	_, err := spawn(world, data)
	check(err)

	total_spawn_time^ += time.tick_since(start)

	switch a in data {
	case Player:
		append(&info.player_expected, a)
	case Enemy:
		append(&info.enemy_expected, a)
	case Ball:
		append(&info.ball_expected, a)
	case Physics_Square:
		append(&info.physics_square_expected, a)
	case Ui:
		append(&info.ui_expected, a)
	}
}

@(test)
spawning :: proc(t: ^testing.T) {
	world: World
	defer destroy_world(&world)

	ITERATIONS :: 1000

	verify_info: Verify_Info
	defer destroy_verify(&verify_info)

	total_spawn_time: time.Duration

	for i in 0 ..< ITERATIONS {
		rand.reset(u64(i)) // seed

		r :: rand.float32

		spawn_w_verify_info(
			&world,
			Player {
				pos = {x = r(), y = r()},
				vel = {x = r(), y = r()},
				acc = {x = r(), y = r()},
				hp = {r()},
				atk = {r()},
				sta = {r()},
				mana = {r()},
				tag = {},
			},
			&verify_info,
			&total_spawn_time,
		)

		spawn_w_verify_info(
			&world,
			Enemy {
				pos = {x = r(), y = r()},
				vel = {x = r(), y = r()},
				acc = {x = r(), y = r()},
				hp = {r()},
				atk = {r()},
				sta = {r()},
				tag = {},
			},
			&verify_info,
			&total_spawn_time,
		)

		spawn_w_verify_info(
			&world,
			Ball{pos = {x = r(), y = r()}, vel = {x = r(), y = r()}},
			&verify_info,
			&total_spawn_time,
		)

		spawn_w_verify_info(
			&world,
			Physics_Square {
				pos = {x = r(), y = r()},
				vel = {x = r(), y = r()},
				acc = {x = r(), y = r()},
			},
			&verify_info,
			&total_spawn_time,
		)

		spawn_w_verify_info(&world, Ui{pos = {x = r(), y = r()}}, &verify_info, &total_spawn_time)

		// final test time is misleading bc verify takes a long time
		verify(t, &world, verify_info)
	}

	log.info("total time spent on spawning:", total_spawn_time)

	testing.expect(t, len(world.a_player.data) == ITERATIONS)
	testing.expect(t, len(world.a_enemy.data) == ITERATIONS)
	testing.expect(t, len(world.a_ball.data) == ITERATIONS)
	testing.expect(t, len(world.a_physics_square.data) == ITERATIONS)
	testing.expect(t, len(world.a_ui.data) == ITERATIONS)
}
