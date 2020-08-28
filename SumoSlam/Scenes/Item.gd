extends RigidBody2D
class_name Item

var _class

var state
var size

var curr_collider

func is_class(comp_class): 
	return comp_class == _class

func get_class(): 
	return _class
	
func item_init(i_class, i_pos, i_state, i_size, i_collider):
	self._class = i_class
	self.position = i_pos
	self.state = i_state
	self.size = i_size
	self.curr_collider = i_collider
	self.set_as_toplevel(true)
	randomize()
	
#func _ready():
#	pass

func set_collidable(value):
	if curr_collider:
		curr_collider.set_disabled(!value)

func _physics_process(__):
	if self.global_position.x > get_viewport_rect().size.x or self.global_position.x < 0:
		self.global_position.x = wrapf(self.global_position.x, 0, get_viewport_rect().size.x)
