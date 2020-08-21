extends KinematicBody2D

const PUSH_POWER = 150

const FLOOR = Vector2(0, -1)

var velocity = Vector2()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func pushed(__, pusher_dir, pusher_velocity, pusher_scale):
	
	
	
#	# Update status.
#	sumo_state[PUSH_STUN] = PUSH_STUNNED
#	$SumoAnim.play("Stun" + skin)

		
	# Set stun gravity and initial velocity.
#	gravity = DOWN_GRAVITY
	var x_component = (1.0 / scale.y) * pusher_dir * PUSH_POWER
	var y_component = Vector2(0, -1) * (PUSH_POWER / 2.0)
	
	var rel_scale = pusher_scale.y / float(scale.y)
	var momentum = pusher_velocity / 2
	
	velocity = rel_scale * momentum + x_component + y_component
	velocity = move_and_slide(velocity, FLOOR)
	
	return momentum * (1 / rel_scale)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
