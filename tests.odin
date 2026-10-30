package main

import "core:fmt"
import "core:testing"

import "ecs"

check :: proc(err: ecs.Error, msg := #caller_expression) {
	if err != nil {
		fmt.panicf("%s: %s", msg, ecs.error_string(err))
	}
}

spawn_w_verify_info :: proc(world: ^World, data: Archetype, info: ^Verify_Info) {
	_, err := spawn(world, data)
	check(err)

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

	for i in 0 ..< ITERATIONS {
		f := f32(i)

		spawn_w_verify_info(
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
			&verify_info,
		)

		spawn_w_verify_info(
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
			&verify_info,
		)

		spawn_w_verify_info(&world, Ball{pos = {x = f, y = f}, vel = {x = f, y = f}}, &verify_info)

		spawn_w_verify_info(
			&world,
			Physics_Square{pos = {x = f, y = f}, vel = {x = f, y = f}, acc = {x = f, y = f}},
			&verify_info,
		)

		spawn_w_verify_info(&world, Ui{pos = {x = f, y = f}}, &verify_info)

		verify(t, &world, verify_info)
	}

	testing.expect(t, len(world.a_player.data) == ITERATIONS)
	testing.expect(t, len(world.a_enemy.data) == ITERATIONS)
	testing.expect(t, len(world.a_ball.data) == ITERATIONS)
	testing.expect(t, len(world.a_physics_square.data) == ITERATIONS)
	testing.expect(t, len(world.a_ui.data) == ITERATIONS)
}
