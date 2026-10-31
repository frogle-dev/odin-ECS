package main

Vec2 :: [2]f32

Position :: struct {
	using pos: Vec2,
}

Velocity :: struct {
	using vel: Vec2,
}

Acceleration :: struct {
	using acc: Vec2,
}

Health :: struct {
	hp: f32,
}

Attack :: struct {
	atk: f32,
}

Stamina :: struct {
	stamina: f32,
}

Mana :: struct {
	mana: f32,
}

PlayerTag :: struct {}
EnemyTag :: struct {}

@(archetype)
Player :: struct {
	pos:  Position,
	vel:  Velocity,
	acc:  Acceleration,
	hp:   Health,
	atk:  Attack,
	sta:  Stamina,
	mana: Mana,
	tag:  PlayerTag,
}

@(archetype)
Enemy :: struct {
	pos: Position,
	vel: Velocity,
	acc: Acceleration,
	hp:  Health,
	atk: Attack,
	sta: Stamina,
	tag: EnemyTag,
}

@(archetype)
Ball :: struct {
	pos: Position,
	vel: Velocity,
}

@(archetype)
Physics_Square :: struct {
	pos: Position,
	vel: Velocity,
	acc: Acceleration,
}

@(archetype)
Ui :: struct {
	pos: Position,
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

@(system)
enemy_sys :: proc(query: #soa[]struct {
		hp:      ^Health,
		atk:     ^Attack,
		stamina: ^Stamina,
		enemy:   ^EnemyTag,
	}) {
}

@(system)
warrior :: proc(query: #soa[]struct {
		hp:      ^Health,
		atk:     ^Attack,
		stamina: ^Stamina,
		player:  ^PlayerTag,
	}) {
}

@(system)
wizard :: proc(query: #soa[]struct {
		hp:      ^Health,
		atk:     ^Attack,
		stamina: ^Stamina,
		mana:    ^Mana,
		player:  ^PlayerTag,
	}) {
}
