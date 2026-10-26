package main

Vec2 :: [2]f32

Position :: struct {
	pos: Vec2,
}

Velocity :: struct {
	vel: Vec2,
}

Acceleration :: struct {
	acc: Vec2,
}

@(system)
movement :: proc(query: #soa[]struct {
		pos: ^Position,
		vel: ^Velocity,
	}) {
	for data in query {
		data.pos.pos += data.vel.vel
	}
}

@(system)
physics :: proc(query: #soa[]struct {
		pos: ^Position,
		vel: ^Velocity,
		acc: ^Acceleration,
	}) {
	for data in query {
		data.vel.vel += data.acc.acc
		data.pos.pos += data.vel.vel
	}
}
