extends KinematicBody2D
class_name Structure

var _class

var id
var state
var size
var dir

var curr_collider

var prev_hit

func is_class(comp_class): 
	return comp_class == _class

func get_class(): 
	return _class
	
func structure_init(s_class, s_id, s_name, s_pos, s_state, s_size, s_collider):
	self._class = s_class
	self.id = s_id
	self.name = s_name
	self.position = s_pos
	self.state = s_state
	self.size = s_size
	self.curr_collider = s_collider
	self.dir = Vector2.ZERO
	self.prev_hit = 0
	randomize()
	
func set_collidable(value):
	if curr_collider:
		curr_collider.set_disabled(!value)
		
func switch_colliders(off, on):
	off.set_disabled(true)
	on.set_disabled(false)
	curr_collider = on

#func _ready():
#	pass
	
#func _process(delta):
#	pass
