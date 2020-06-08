extends Node2D

# Player initializations
const PLAYER_SPAWN = {
	0: { 'POS': Vector2(168, 63.5), 'FLAGS_POS': Vector2(168, 95)},
	1: { 'POS': Vector2(632, 63.5), 'FLAGS_POS': Vector2(632, 95)},
	2: { 'POS': Vector2(232, 63.5), 'FLAGS_POS': Vector2(232, 95)},
	3: { 'POS': Vector2(568, 63.5), 'FLAGS_POS': Vector2(568, 95)}
}

# Sumo circle initializations
const SUMOCIRCLE_SPAWN = {
	0: { 'POS': Vector2(400.5, 230) },
	1: { 'POS': Vector2(240.5, 406) },
	2: { 'POS': Vector2(560.5, 406) }
}

# Sushi stand initializations
const SUSHISTAND_SPAWN = {
	0: { 'POS': Vector2(200, 167) },
	1: { 'POS': Vector2(600, 167) },
	2: { 'POS': Vector2(240.5, 415) },
	3: { 'POS': Vector2(560.5, 415) }
}

# Arch initializations
const ARCH_SPAWN = {
	0: { 'POS': Vector2(400, 403) }
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
