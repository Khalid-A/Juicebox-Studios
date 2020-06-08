extends RigidBody2D

enum {AVAILABLE, UNAVAILABLE}

var state
var stand

func _ready():
	pass

func is_class(_class): 
	return _class == "Sushi"

func get_class(): 
	return "Sushi"

func init(p_pos):
	self.position = p_pos
	self.stand = get_parent()
	self.state = AVAILABLE
	$Sprite.play('Sushi%s' % [randi() % 5])
	self.set_as_toplevel(true)

func reparent(new_parent, set_available):
	var old_position = global_position
	get_parent().remove_child(self)
	new_parent.add_child(self)
	
	if set_available:
		set_mode(MODE_RIGID)
		set_as_toplevel(true)
		set_collision_mask_bit(1, true)
		global_position = old_position
		set_linear_velocity(get_parent().get_sushi_trajectory())
		yield(get_tree().create_timer(0.5), "timeout")
		state = AVAILABLE
	else:
		set_mode(MODE_KINEMATIC)
		set_as_toplevel(false)
		set_collision_mask_bit(1, false)
		position = Vector2(0.0, 0.0) 
		state = UNAVAILABLE

func _physics_process(__):
	if self.global_position.x > get_viewport_rect().size.x or self.global_position.x < 0:
		self.global_position.x = wrapf(self.global_position.x, 0, get_viewport_rect().size.x)
	
	
	