extends Node2D

const SUSHISTAND_NODE = preload("res://Scenes/SushiStand.tscn")

# Sushi manager variables
var num_sushi
var num_sushi_stands
var max_sushi
var cook_time
var sushi_stands

func _ready():
	sushi_stands[randi() % num_sushi_stands].spawn_sushi()

func init(p_num_sushi_stands, p_sushi_stand_inits, p_max_sushi, p_cook_time):
	self.num_sushi = 0
	self.num_sushi_stands = p_num_sushi_stands
	self.max_sushi = p_max_sushi
	self.cook_time = p_cook_time
	self.sushi_stands = []
	for id in num_sushi_stands:
		var new_stand = SUSHISTAND_NODE.instance()
		new_stand.init(id, 'SushiStand %s' % [id+1], p_sushi_stand_inits[id]['POS'], self)
		add_child(new_stand)
		sushi_stands.push_back(new_stand)
		
func spawn_sushi():
	sushi_stands[randi() % num_sushi_stands].spawn_sushi()