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
player :: [?]typeid{Position, Velocity, Acceleration, Health, Attack, Stamina, Mana, PlayerTag}
@(archetype)
enemy :: [?]typeid{Position, Velocity, Acceleration, Health, Attack, Stamina, EnemyTag}
@(archetype)
ball :: [?]typeid{Position, Velocity}
@(archetype)
physics_square :: [?]typeid{Position, Velocity, Acceleration}
@(archetype)
ui :: [?]typeid{Position}

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
