extends Entity

const SCREENWRAP_NODE = preload("res://Scenes/ScreenWrapNode.tscn")

# Sumo signals
signal death(player, attacker)

# Sumo constants
const SPEED = 200
const ACCELERATION_TIME = 0.2
const DECELERATION_TIME = 0.1

const DASH_DISTANCE = 70
const DASH_TIME = 0.2

const MAX_JUMP_HEIGHT = 128
const UP_TIME = 0.9
const DOWN_TIME = 0.7
const HOLD_UP_GRAVITY = 2 * MAX_JUMP_HEIGHT / (UP_TIME * UP_TIME)
const RELEASED_UP_GRAVITY = 3 * HOLD_UP_GRAVITY
const DOWN_GRAVITY = 2 * MAX_JUMP_HEIGHT / (DOWN_TIME * DOWN_TIME)
const SLAM_GRAVITY = 5 * DOWN_GRAVITY

const SLAM_STUN_TIME = 0.5

const PUSH_DISTANCE = 60
const PUSH_TIME = 0.3
const PUSH_POWER = 30
const PUSH_STUN_TIME = 1.0

const BLOCK_POWER = 100
const BLOCK_TIME = 1.0
const BLOCK_STUN_TIME = 1.0
const TOSS_POWER = 220

const BOUNCE_POWER = 200

const SUSHI_EATING_TIME = 2.0

const TAUNTING_TIME = 1.0
const TAUNT_STUN_TIME = 1.0

const MASS = 10.0
const MAX_SCALE_UP = 0.5 

const FLOOR = Vector2(0, -1)

# Sumo variables
enum {GROUNDED, AIRBORNE, DOUBLE_JUMPING}
enum {DASHING, DASHED, DASH_READY}
enum {SLAMMING, NOT_SLAMMING, SLAMMED}

enum {PUSHING, NOT_PUSHING}
enum {PUSH_STUNNED, NOT_PUSH_STUNNED}

enum {BLOCKING, NOT_BLOCKING}
enum {BLOCK_STUNNED, NOT_BLOCK_STUNNED}

enum {TOSSED, NOT_TOSSED}
enum {HOLDING, EATING, NOT_HOLDING}

enum {TAUNTING, NOT_TAUNTING}
enum {TAUNT_STUNNED, NOT_TAUNT_STUNNED}

enum {WEAK, MID, HEAVY}
enum {ALIVE, DYING}

enum {JUMP, DASH, SLAM, 
		PUSH, PUSH_STUN, 
		BLOCK, BLOCK_STUN, 
		TOSS, FOOD, 
		TAUNT, TAUNT_STUN,
		LIFE}

var sumo_state = [GROUNDED, DASH_READY, NOT_SLAMMING, 
					NOT_PUSHING, NOT_PUSH_STUNNED, 
					NOT_BLOCKING, NOT_BLOCK_STUNNED,
					NOT_TOSSED, NOT_HOLDING, 
					NOT_TAUNTING, NOT_TAUNT_STUNNED,
					ALIVE]

# Sumo variables
var gravity = DOWN_GRAVITY
var push_stun_timer = 0.0
var taunt_stun_timer = 0.0
var blocker = null
var sushi = null
var sushi_anim = ""

export (bool) var isOriginal = false

func _ready():
	if isOriginal:
		var wrap = SCREENWRAP_NODE.instance()
		wrap.instancePath = "res://Scenes//Player.tscn"
		add_child(wrap)
	else:
		set_physics_process(false)
	
func init(p_id, p_name, p_pos, p_skin, p_color):
	entity_init("Player", p_id, p_name, p_pos, p_skin, p_color, $CapsuleCollider.get_shape().radius)
	self.isOriginal = true
	play_anim("Idle")

# Controls physics processes for the Sumo.
func _physics_process(delta):
	
	# Only perform actions if the Sumo isn't in the process of dying
	if sumo_state[LIFE] == ALIVE:
		# Reset Sumo states if on ground.
		if is_on_floor():
			sumo_state[JUMP] = GROUNDED
			sumo_state[DASH] = DASH_READY
			if sumo_state[TOSS] == TOSSED:
				blocker = null
				sumo_state[TOSS] = NOT_TOSSED
		
		# If push stunned, player doesn't have control of Sumo.
		if sumo_state[PUSH_STUN] == PUSH_STUNNED:
			push_stun_loop(delta)
			return
		
		# If block stunned, player doesn't have control of Sumo.
		if sumo_state[BLOCK_STUN] == BLOCK_STUNNED:
			block_stun_loop()
			return
			
		# If taunt stunned, player is vulnerable to double slam.
		if sumo_state[TAUNT_STUN] == TAUNT_STUNNED:
			taunt_stun_loop(delta)
			return
		
		# If just got tossed, only apply gravity.
		if sumo_state[TOSS] == TOSSED:
			velocity.y += scale.y * gravity * delta
			velocity = move_and_slide(velocity, FLOOR)
			return
		
		if sumo_state[FOOD] == EATING or sumo_state[TAUNT] == TAUNTING:
			idle(delta)
			velocity.y += scale.y * gravity * delta
			velocity = move_and_slide(velocity, FLOOR)
			return
			
		# Handle slam impact.
		if sumo_state[SLAM] == SLAMMING and is_on_floor():
			sumo_state[SLAM] = SLAMMED
			play_anim("SlamImpact")
			$SlamTimer.start(SLAM_STUN_TIME)
			velocity = Vector2.ZERO
			return
		elif sumo_state[SLAM] == SLAMMED:
			return
		
		# Handle block input.
		if valid_trigger("block"):
			block()
		
		# Handle eat input.
		if valid_trigger("eat"):
			eat_sushi()
				
		# Handle taunt input.
		if valid_trigger("taunt"):
			taunt()
		
		# X movement
		horizontal_movement(delta)
		
		# Y movement
		if sumo_state[DASH] != DASHING:
			vertical_movement(delta)
		
		# Move according to velocity.
		velocity = move_and_slide(velocity, FLOOR)
		
		# Check all player collisions.
		player_collision(delta)
		
		# Check all object collisions.
		object_collision(delta)

# Handles horizontal movement.
func horizontal_movement(delta):
	# Handles dash or push input.
	if valid_trigger("dash"):
		dash()
	elif valid_trigger("push"):
		push()
	
	# If Sumo has dashed into a wall or platform, the dash is over.
	if is_on_wall():
		if sumo_state[DASH] == DASHING:
			sumo_state[DASH] = DASHED
		elif sumo_state[PUSH] == PUSHING:
			sumo_state[PUSH] = NOT_PUSHING
	
	# Handle non-dash and non-push horizontal input.
	if sumo_state[DASH] != DASHING and sumo_state[PUSH] != PUSHING:
		if Input.is_action_pressed("ui_right%s" % id):
			dir = Vector2.RIGHT
			move(delta)
		elif Input.is_action_pressed("ui_left%s" % id):
			dir = Vector2.LEFT
			move(delta)
		else:
			idle(delta)

# Handles vertical movement.
func vertical_movement(delta):
	# Handle jumping input.
	if Input.is_action_just_pressed("ui_jump%s" % id):
		match sumo_state[JUMP]:
			GROUNDED:
				initial_jump()
			AIRBORNE:
				double_jump()
			DOUBLE_JUMPING:
				pass
	
	# Handle slam and canceled jump input.
	if sumo_state[JUMP] != GROUNDED:
		if Input.is_action_just_pressed("ui_down%s" % id):
			slam()
		elif Input.is_action_just_released("ui_jump%s" % id):
			released_jump()
	
	# Fall if past peak of jump.
	if velocity.y > 0 and sumo_state[SLAM] != SLAMMING:
		fall()
	
	# Update velocity according to gravity.
	velocity.y += scale.y * gravity * delta
	
func move(delta):
	# Update x velocity depending on whether decelerating or accelerating.
	if dir.x * velocity.x < 0:
		velocity.x += (dir.x * SPEED - velocity.x) * delta / DECELERATION_TIME
	else:
		velocity.x += (dir.x * SPEED - velocity.x) * delta / ACCELERATION_TIME
	
	# Update sprite to reflect movement.
	if valid_trigger("walk"):
		play_anim("Walk")
	$SumoAnim.set_scale(Vector2(dir.x,1))

# Halts the Sumo's x-axis movement and controls animation accordingly.
func idle(delta):
	velocity.x += -velocity.x * delta / DECELERATION_TIME
	if valid_trigger("idle"):
		if sumo_state[FOOD] == EATING:
			play_anim("Eating")
		elif sumo_state[TAUNT] == TAUNTING:
			play_anim("Taunt")
		else:
			play_anim("Idle")

# Begins the Sumo's dash.
func dash():
	# Begin dash.
	sumo_state[DASH] = DASHING
	var dash_speed = DASH_DISTANCE / DASH_TIME
	velocity.x = dir.x * dash_speed
	velocity.y = 0
	
	# Start DashTimer, which will stop dash once DASH_TIME has passed.
	play_anim("Dash")
	$DashTimer.start(DASH_TIME)
	
	get_parent().player_stats[id]['dashes'] += 1

# Begins the Sumo's jump trajectory and controls animation accordingly.
func initial_jump():
#	play_audio("res://Sounds//jump.wav")
	sumo_state[JUMP] = AIRBORNE
	gravity = HOLD_UP_GRAVITY
	velocity.y = -sqrt(2 * scale.y * gravity * MAX_JUMP_HEIGHT)
	if valid_trigger("jump"):
		play_anim("Jump")

# Begins the Sumo's second jump.
func double_jump():
#	play_audio("res://Sounds//jump.wav")
	sumo_state[JUMP] = DOUBLE_JUMPING
	if sumo_state[SLAM] == SLAMMING:
		sumo_state[SLAM] = NOT_SLAMMING
		$CapsuleCollider.set_disabled(false)
		$SlamCollider.set_disabled(true)
	gravity = HOLD_UP_GRAVITY
	velocity.y = -sqrt(2 * scale.y * gravity * MAX_JUMP_HEIGHT)
	if valid_trigger("jump"):
		play_anim("Jump")
		
	get_parent().player_stats[id]['double_jumps'] += 1

# Changes the Sumo's gravity in accordance with a jump cancel or jump conclusion.
func released_jump():
	gravity = RELEASED_UP_GRAVITY

# Changes the Sumo's gravity for falling and controls animation accordingly.
func fall():
	if sumo_state[JUMP] != DOUBLE_JUMPING:
		sumo_state[JUMP] = AIRBORNE
	if valid_trigger("fall"):
		play_anim("Fall")
	gravity = DOWN_GRAVITY

# Changes the Sumo's gravity for slamming and controls animation accordingly.
func slam():
#	play_audio("res://Sounds//slam-sound.wav")
	play_anim("Slam")
	$CapsuleCollider.set_disabled(true)
	$SlamCollider.set_disabled(false)
	sumo_state[SLAM] = SLAMMING
	sumo_state[PUSH] = NOT_PUSHING
	gravity = SLAM_GRAVITY

# Perform a push.
func push():
	sumo_state[PUSH] = PUSHING
	
	# Start push animation.
#	play_audio("res://Sounds//push.wav")
	play_anim("Push")
	$PushTimer.start(PUSH_TIME)

	var push_speed = PUSH_DISTANCE / PUSH_TIME
	match dir:
		Vector2.LEFT:
			$PushColliderLeft.set_disabled(false)
		Vector2.RIGHT:
			$PushColliderRight.set_disabled(false)
	velocity.x = dir.x * push_speed
	velocity.y = 0

# Perform a block.
func block():
#	play_audio("res://Sounds//block.wav")
	sumo_state[BLOCK] = BLOCKING
	play_anim("Block")
	$BlockTimer.start(BLOCK_TIME)
	
# Taunt
func taunt():
	sumo_state[TAUNT] = TAUNTING
#	play_audio("res://Sounds//jump.wav")
	$TauntTimer.start(TAUNTING_TIME)
	
	var taunt_area
	match dir:
		Vector2.LEFT:
			taunt_area = $TauntAreaLeft
		Vector2.RIGHT:
			taunt_area = $TauntAreaRight
	
	# Taunt everything in the Area2D.
	for body in taunt_area.get_overlapping_bodies():
		if body != self and body.has_method("taunted") and body.dir != self.dir:
			body.taunted(id)

# Triggers player death and respawn
func death(attacker_id=-1):
	# Drop the sushi on death.
	if sumo_state[FOOD] == HOLDING or sumo_state[FOOD] == EATING: 
		drop_sushi()
	
	# If you're getting killed, so will the guy right beneath you.
	if blocker != null:
		blocker.sumo_state[BLOCK] = NOT_BLOCKING
	
#	play_audio("res://Sounds/death.wav")
	
	# Start the dying sequence.
	if sumo_state[LIFE] != DYING:
		sumo_state[LIFE] = DYING
		
		# Move up so that the death animation plays in the correct place.
		global_position.y -= 16
		
		# Make sure death animation plays behind other players.
		z_index = -1
		play_anim("Death")
		yield($SumoAnim, "animation_finished")
		
		# Send signal to game indicating death.
		emit_signal('death', self, attacker_id)

# Begins launch and stun as a result of an opponent's block.
func blocked(p_blocker):
	# Update status.
	sumo_state[BLOCK_STUN] = BLOCK_STUNNED
	sumo_state[SLAM] = NOT_SLAMMING
	play_anim("BlockStun")
	blocker = p_blocker
	
	# Drop the sushi
	if sumo_state[FOOD] == HOLDING or sumo_state[FOOD] == EATING: 
		drop_sushi()
	
	# Set gravity.
	gravity = DOWN_GRAVITY
	
	get_parent().player_stats[id]['blocked'] += 1
	get_parent().player_stats[blocker.id]['blocks'] += 1

# Begins launch and stun as a result of an opponent's push.
func pushed(pusher_id, pusher_dir, pusher_velocity, pusher_size):
	# Update status.
	sumo_state[PUSH_STUN] = PUSH_STUNNED
	
	dir = pusher_dir * Vector2(-1, 0)
	$SumoAnim.set_scale(Vector2(pusher_dir.x * -1, 1))

	play_anim("PushStun")
		
	# Drop the sushi
	if valid_trigger("drop_sushi"): 
		drop_sushi()
		
	# Set stun gravity and initial velocity.
	gravity = DOWN_GRAVITY
	
	var x_component = (1.0 / scale.y) * pusher_dir * PUSH_POWER
	var y_component = Vector2(0, -1) * (PUSH_POWER / 2.0)
	var momentum = Global.collision_momentum(pusher_velocity, pusher_size, size)

	velocity += momentum + x_component + y_component
	
	velocity = move_and_slide(velocity, FLOOR)
	
	get_parent().player_stats[id]['pushed'] += 1
	get_parent().player_stats[pusher_id]['pushes'] += 1
	
func taunted(taunter_id):
	# Update status.
	sumo_state[TAUNT_STUN] = TAUNT_STUNNED
	play_anim("TauntStun")
	
	# Drop the sushi
	if valid_trigger("drop_sushi"): 
		drop_sushi()
	
	velocity = Vector2(0, 0)
	
	get_parent().player_stats[id]['taunted'] += 1
	get_parent().player_stats[taunter_id]['taunts'] += 1
	
# This is the loop that plays while the player is push-stunned.
func push_stun_loop(delta):
	# Update timer.
	push_stun_timer += delta
	
	# Only end stun once stun time expired and on floor.
	if push_stun_timer > PUSH_STUN_TIME and is_on_floor():
		push_stun_timer = 0.0
		sumo_state[PUSH_STUN] = NOT_PUSH_STUNNED
		return
	
	# Apply gravity and move.
	velocity.y += scale.y * gravity * delta
	velocity = move_and_slide(velocity, FLOOR)

# This is the loop that plays while the player is block-stunned.
func block_stun_loop():
	# Only end stun once blocker done blocking.
	if blocker.sumo_state[BLOCK] == NOT_BLOCKING:
		# Set state.
		sumo_state[BLOCK_STUN] = NOT_BLOCK_STUNNED
		
		# Get tossed in direction that blocker is facing.
		sumo_state[TOSS] = TOSSED
		play_anim("Stun")
		var toss_power = TOSS_POWER / scale.y
		velocity = move_and_slide(Vector2(dir.x,-1).normalized() * toss_power + blocker.velocity, FLOOR)
		return
	
	# Stay fixed to the blocker.
	global_position = blocker.global_position
	global_position.y -= 2 * blocker.scale.y * blocker.get_node("CapsuleCollider").shape.height + 1
	$SumoAnim.scale = blocker.get_node("SumoAnim").scale
	
# This is the loop that plays while the player is taunt-stunned.
func taunt_stun_loop(delta):
	
	taunt_stun_timer += delta
	
	# Only end stun once stun time expired.
	if taunt_stun_timer > TAUNT_STUN_TIME:
		taunt_stun_timer = 0.0
		sumo_state[TAUNT_STUN] = NOT_TAUNT_STUNNED
		return
		
	# Apply gravity and move.
	velocity.y += scale.y * gravity * delta
	velocity = move_and_slide(velocity, FLOOR)
	
func object_collision(delta):
	
	Global.set_entity_mask_bits(self, ["Items", "Structures"], true)
	
	# Check for collisions
	var collision = move_and_collide(velocity * delta, false, true, true)
	if collision:
		var object = collision.collider
		
		if object.is_class("Sushi") and valid_trigger("grab_sushi"):
			hold_sushi(object)
			
		elif sumo_state[PUSH] == PUSHING and object.has_method("pushed"):
			object.pushed(id, dir, velocity, size)
			velocity -= Global.collision_momentum(velocity, object.size, size)

	Global.set_entity_mask_bits(self, ["Items", "Structures"], false)

# Check for player collisions.
func player_collision(delta):
	# Check player layer for collisions.
	Global.set_entity_mask_bits(self, "Players", true)
	
	# Check for collisions
	var collision = move_and_collide(velocity * delta, true, true, true)
	if collision and collision.collider.is_class(self._class) and collision.collider.blocker != self:
		var other = collision.collider
		
		if sumo_state[PUSH] == PUSHING and other.sumo_state[SLAM] == NOT_SLAMMING:
			other.pushed(id, dir, velocity, size)
			velocity -= Global.collision_momentum(velocity, other.size, size)
		
		# Other player dies.
		elif sumo_state[SLAM] == SLAMMING and other.sumo_state[BLOCK] == NOT_BLOCKING:
			other.death(id)
			
		# Other player blocked slam.
		elif sumo_state[SLAM] == SLAMMING and other.sumo_state[SLAM] == NOT_SLAMMING and other.sumo_state[BLOCK] == BLOCKING:
			blocked(other)
			other.get_node("BlockTimer").start(BLOCK_TIME)
			
		# Players bounce off of each other.
		elif other.sumo_state[LIFE] == ALIVE:
			other.bounce(global_position)
			bounce(other.global_position)
	
	# Reset player collision layer.
	Global.set_entity_mask_bits(self, "Players", false)

# Bounce away from "from_pos".
func bounce(from_pos):
	var bounce_dir = from_pos.direction_to(global_position)
	velocity = bounce_dir * BOUNCE_POWER

# Reparent the sushi to be a child of the player
func hold_sushi(node):
	if node.state == node.AVAILABLE and sumo_state[FOOD] == NOT_HOLDING:
		sumo_state[FOOD] = HOLDING
		sushi_anim = "-Sushi"
		sushi = node
		sushi.visible = false
		sushi.reparent(self, false)

# Reparent the sushi to make it a child of the Sushi Manager
func drop_sushi():
	sumo_state[FOOD] = NOT_HOLDING
	sushi_anim = ""
	sushi.visible = true
	if sushi:
		sushi.reparent(sushi.stand, true)
	sushi = null

# Eat sushi
func eat_sushi():
#	play_audio("res://Sounds//jump.wav")
	sumo_state[FOOD] = EATING
	sushi_anim = ""
	$EatTimer.start(SUSHI_EATING_TIME)
	
# Runs when DashTimer times out, and ends a dash.
func _on_DashTimer_timeout():
	sumo_state[DASH] = DASHED
	
func _on_PushTimer_timeout():
	sumo_state[PUSH] = NOT_PUSHING
	$PushColliderLeft.set_disabled(true)
	$PushColliderRight.set_disabled(true)
	
# Runs when SlamTimer times out, and ends the slam stun.
func _on_SlamTimer_timeout():
	sumo_state[SLAM] = NOT_SLAMMING
	$CapsuleCollider.set_disabled(false)
	$SlamCollider.set_disabled(true)

# Runs when BlocokTimer times out, and ends the block.
func _on_BlockTimer_timeout():
	sumo_state[BLOCK] = NOT_BLOCKING

# Runs when EatTimer times out, and ends the feast ;-).
func _on_EatTimer_timeout():
	sumo_state[FOOD] = NOT_HOLDING
	update_calories()
	get_parent().sushi_count -= 1
	if sushi:
		sushi.queue_free()
	sushi = null
	
func _on_TauntTimer_timeout():
	sumo_state[TAUNT] = NOT_TAUNTING
	
func _on_SumoAnim_timeout():
	pass
	
func update_calories():
	get_parent().player_stats[id]['calories'] += get_parent().SUSHI_CALORIES
	get_parent().player_stats[id]['total_calories'] += get_parent().SUSHI_CALORIES
	
	var prev_height = scale.y * $CapsuleCollider.shape.height

	var scale_up = MAX_SCALE_UP * (get_parent().player_stats[id]['calories'] / get_parent().CALORIE_THRESHOLDS[HEAVY])
	
	var new_scale = 1.0 + min(scale_up, MAX_SCALE_UP)

	scale = Vector2(new_scale, new_scale)
	size = scale.y * $CapsuleCollider.get_shape().radius
		
	position.y -= scale.y * $CapsuleCollider.shape.height - prev_height

func synchronize(player):
	var playerAnim = $SumoAnim
	var flip_h = player.dir == Vector2.LEFT
	var animation = playerAnim.get_animation()
	var frame = playerAnim.get_frame()
	$SumoAnim.set_flip_h(flip_h)
	$SumoAnim.set_animation(animation)
	$SumoAnim.set_frame(frame)

#func play_audio(file):
#	$SumoAudio.set_stream(load(file))
#	$SumoAudio.play()
	
func play_anim(action):
	
	var extension
	
	match action:
		
		"Idle", "Walk", "Jump", "Fall", "Slam", "Push", "Taunt", "Dash":
			extension = sushi_anim + skin
			
		"Eating", "Block", "TauntStun", "BlockStun", "PushStun", "Stun", "Death", "SlamImpact":
			extension = skin
			
	$SumoAnim.play(action + extension)
		
func valid_trigger(action):
	
	match action:
		"walk":
			return sumo_state[PUSH] == NOT_PUSHING \
					and sumo_state[BLOCK] == NOT_BLOCKING \
					and sumo_state[TAUNT] == NOT_TAUNTING \
					and is_on_floor()
		"idle":
			return sumo_state[PUSH] == NOT_PUSHING \
					and sumo_state[BLOCK] == NOT_BLOCKING \
					and is_on_floor()
		"jump":
			return sumo_state[PUSH] == NOT_PUSHING \
					and sumo_state[BLOCK] == NOT_BLOCKING \
					and sumo_state[TAUNT] == NOT_TAUNTING
		"fall":
			return sumo_state[PUSH] == NOT_PUSHING \
					and sumo_state[BLOCK] == NOT_BLOCKING
		"push":
			return Input.is_action_just_pressed("ui_push%s" % id) \
					and !Input.is_action_pressed("ui_up%s" %id) \
					and sumo_state[PUSH] == NOT_PUSHING \
					and sumo_state[SLAM] == NOT_SLAMMING \
					and sumo_state[BLOCK] == NOT_BLOCKING \
					and sumo_state[TAUNT] == NOT_TAUNTING
		"block":
			 return Input.is_action_just_pressed("ui_push%s" % id) \
					and Input.is_action_pressed("ui_up%s" % id) \
					and sumo_state[BLOCK] == NOT_BLOCKING \
					and sumo_state[TAUNT] == NOT_TAUNTING
		"dash":
			return Input.is_action_just_pressed("ui_dash%s" % id) \
					and sumo_state[DASH] == DASH_READY \
					and sumo_state[SLAM] == NOT_SLAMMING
		"eat":
			return Input.is_action_just_pressed("ui_eat%s" % id) \
					and sumo_state[FOOD] == HOLDING \
					and sumo_state[BLOCK] == NOT_BLOCKING
		"taunt":
			return Input.is_action_just_pressed("ui_taunt%s" % id) \
					and sumo_state[TAUNT] == NOT_TAUNTING \
					and sumo_state[SLAM] == NOT_SLAMMING \
					and sumo_state[BLOCK] == NOT_BLOCKING \
					and is_on_floor()
		"grab_sushi":
			return sumo_state[FOOD] == NOT_HOLDING \
					and sumo_state[SLAM] == NOT_SLAMMING \
					and sumo_state[TAUNT] == NOT_TAUNTING \
					and sumo_state[PUSH_STUN] == NOT_PUSH_STUNNED \
					and sumo_state[DASH] != DASHING
		"drop_sushi":
			return sumo_state[FOOD] == HOLDING or sumo_state[FOOD] == EATING