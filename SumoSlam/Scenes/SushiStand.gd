extends RigidBody2D

const SUSHI_NODE = preload("res://Scenes/Sushi.tscn")

const LAUNCH_X = [-100, -75, -50, 50, 75, 100]
const LAUNCH_Y = [-75, -65, -55, -45]

const SURPRISE_TIME = 1
const MAX_HITS = 5
const BLAST_MULTIPLIER = 3
const SUSHI_BLAST_COUNT = 8

signal sushi_cooked()

var id
var state
var dir

var size

var hits
var last_hit
var destroyed

enum {WORKING, READY}

func _ready():
	set_mode(MODE_KINEMATIC)
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
	self.size = $StandCollider.get_shape().get_extents().y
	self.state = READY
	self.dir = Vector2.ZERO
	self.hits = 0
	self.last_hit = 0
	self.destroyed = false
	$StandAnim.play("Idle")
	$Chef.play("Idle")

func cook_sushi():
	if state == WORKING: return
	state = WORKING
	$Chef.play("Cooking")
	$CookTimer.start(get_parent().COOK_TIME)
	
func get_sushi_trajectory():
	
	var multiplier = BLAST_MULTIPLIER if destroyed else 1
	
	return Vector2(LAUNCH_X[randi() % LAUNCH_X.size()] * multiplier, 
					LAUNCH_Y[randi() % LAUNCH_Y.size()] * multiplier)

func _on_CookTimer_timeout(count=1):
	state = READY
	$CookTimer.stop()
	
	if !destroyed: 
		$Chef.play("Idle")
	
	for __ in range(count):
		var new_sushi = SUSHI_NODE.instance()
		self.add_child(new_sushi)
		emit_signal('sushi_cooked')
		new_sushi.init(global_position)
		new_sushi.set_linear_velocity(get_sushi_trajectory())
		Global.set_entity_mask_bits(self, "Structures", true)
	
func pushed(__, __, __, __):
	
	last_hit = OS.get_system_time_secs()
	
	react('pushed')
	
func taunted(__):
	
	react('taunted')
	
func react(action):
	
	if destroyed: return
	
	if action == 'pushed':
		$StandAnim.play("Hit")
		hits += 1
		
	$Chef.play("Surprised")
	
	if hits >= MAX_HITS:
		$StandAnim.play("Destroyed")
		$RubbleCollider.set_disabled(false)
		$StandCollider.set_disabled(true)
		destroyed = true
		_on_CookTimer_timeout(SUSHI_BLAST_COUNT)
	else:
		$CookTimer.set_paused(true)
		$ReactionTimer.start(SURPRISE_TIME)

func _on_ReactionTimer_timeout():
	
	if destroyed: 
		$Chef.play("Devastated")
		return
	
	if self.state == WORKING:
		$Chef.play("Cooking")
	else:
		$Chef.play("Idle")
		
	$StandAnim.play("Idle")
	
	$CookTimer.set_paused(false)


