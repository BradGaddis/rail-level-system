class_name LevelEnums extends Node
## Handles typing and simple states

## The mode that a vehicle can be in.
## This includes the player vehicle and enemy vehciles.
enum mode {
	on_rails,
	free
}

enum level_type {
	empty, # Only here so I can use it to assert that there's a type
	space,
	planet,
	water,
	land,
	under_water,
}
