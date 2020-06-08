extends AnimatedSprite

const SUSHI_NODE = preload("res://Scenes/Sushi.tscn")

const LAUNCH_X = [-75, -50, -25, 25, 50, 75]
const LAUNCH_Y = [-75]

signal sushi_cooked()

var id
var state

enum {WORKING, READY}

func _ready():
	randomize()
	# Connect spawning to game node
	var error = self.connect('sushi_cooked', get_parent(), '_on_sushi_cooked')
	if error: print('Sushi cooked signal error: %s' % error)
	cook_sushi()
	
func is_class(_class): 
	return _class == "SushiStand"

func get_class(): 
	return "SushiStand"
	
func init(p_id, p_name, p_pos):
	self.id = p_id
	self.name = p_name
	self.position = p_pos
	self.state = READY
	$Chef.play("Idle")

func cook_sushi():
	if state == WORKING: return
	state = WORKING
	$Chef.play("Cooking")
	$CookTimer.start(get_parent().COOK_TIME)
	
func get_sushi_trajectory():
	return Vector2(LAUNCH_X[randi() % LAUNCH_X.size()], LAUNCH_Y[randi() % LAUNCH_Y.size()])

func _on_SushiTimer_timeout():
	state = READY
	self.stop()
	$Chef.play("Idle")
	var new_sushi = SUSHI_NODE.instance()
	self.add_child(new_sushi)
	emit_signal('sushi_cooked')
	new_sushi.init(global_position)
	new_sushi.set_linear_velocity(get_sushi_trajectory())
	