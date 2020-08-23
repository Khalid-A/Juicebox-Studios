extends KinematicBody2D

# Arch signals
signal victory(challenger, type)

# Arch constants
const COOLDOWN_TIME = 1.5

# Arch identifiers
var id 

# Arch variables
var rung = false
var ringer_id = -1

var last_hit

var size

enum {WEAK, MID, HEAVY}

func _ready():
	var error = self.connect('victory', get_parent(), '_on_victory')
	if error: print('Heavyweight victory signal error: %s' % error)
	rung = false
	
func is_class(_class): 
	return _class == "Arch"

func get_class(): 
	return "Arch"

func init(p_id, p_pos):
	self.id = p_id
	self.position = p_pos
	self.size = $Gong.get_shape().get_extents().y
	self.last_hit = 0
	$Anim.play("Idle")

#func _process(__):
#	pass
	
# Reacts to push from player, triggering gong ring
func pushed(player_id, __, __, __):
	
	# if enough time has elapsed since last gong ring
	if not rung:
		
		# set gong as rung for duration of animation
		rung = true
		$Cooldown.start(COOLDOWN_TIME)
		get_parent().player_stats[player_id]['gong_rings'] += 1
		
		var weight = get_parent().player_stats[player_id]['calories']
		var THRESHOLD = get_parent().CALORIE_THRESHOLDS
		
		# trigger gong reaction corresponding to player weight
		if weight < THRESHOLD[WEAK]:
			$Anim.play("Idle")
			
		elif weight < THRESHOLD[MID]:
			$Anim.play("Hit-Weak")
			
		elif weight < THRESHOLD[HEAVY]:
			$Anim.play("Hit-Mid")
			
		elif weight >= THRESHOLD[HEAVY]:
			$Anim.play("Hit-Heavy")
			if ringer_id < 0:
				ringer_id = player_id

# Once gong has finished ringing, reset
func _on_cooldown():
	
	# if player successfully rang gong, trigger victory
	if ringer_id >= 0:
		emit_signal('victory', ringer_id, 'HEAVYWEIGHT')
	else:
		rung = false
		$Anim.play("Idle")
