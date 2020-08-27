extends KinematicBody2D
class_name Entity

var _class

var id 
var skin
var color
var size
var velocity 
var dir

func is_class(comp_class): 
	return comp_class == _class

func get_class(): 
	return _class

func entity_init(e_class, e_id, e_name, e_pos, e_skin, e_color, e_size):
	self._class = e_class
	self.id = e_id
	self.name = e_name
	self.position = e_pos
	self.skin = e_skin
	self.color = e_color
	self.size = e_size
	self.velocity = Vector2()
	self.dir = Vector2.RIGHT
	randomize()

func _ready():
	var error = self.connect('death', get_tree().get_root().get_node('Game'), '_on_player_death')
	if error: print('Entity death signal error: %s' % error)

func _physics_process(__):
	
	# simple wraparound
	self.global_position.x = wrapf(self.global_position.x, 0, get_viewport_rect().size.x)
	
	
