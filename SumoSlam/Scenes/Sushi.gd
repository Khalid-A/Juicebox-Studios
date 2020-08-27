extends Item

enum {AVAILABLE, UNAVAILABLE}

const PUSH_POWER = 1500

var stand

func _ready():
	pass

func init(p_pos):
	item_init("Sushi", p_pos, AVAILABLE, $Collider.get_shape().get_extents().y, $Collider)
	self.stand = get_parent()
	$Anim.play('Sushi%s' % [randi() % 5])

func reparent(new_parent, set_available):
	var old_position = global_position
	get_parent().remove_child(self)
	new_parent.add_child(self)
	
	if set_available:
		set_mode(MODE_RIGID)
		set_as_toplevel(true)
		Global.set_entity_mask_bits(self, "Players", true)
		global_position = old_position
		set_linear_velocity(get_parent().get_sushi_trajectory())
		yield(get_tree().create_timer(0.5), "timeout")
		state = AVAILABLE
	else:
		set_mode(MODE_KINEMATIC)
		set_as_toplevel(false)
		Global.set_entity_mask_bits(self, "Players", false)
		position = Vector2(0.0, 0.0) 
		state = UNAVAILABLE
		
func pushed(__, pusher_dir, pusher_velocity, pusher_size):
	
	var momentum = Global.collision_momentum(pusher_velocity, pusher_size, size)
	var x_component = (1.0 / scale.y) * pusher_dir * PUSH_POWER
	var y_component = Vector2(0, -1) * (PUSH_POWER / 2.0)
	
	var push_velocity = momentum + x_component + y_component
	
	apply_impulse(Vector2(), push_velocity)
	
#func _physics_process(__):
#	pass
	
	