extends Structure

# Arch signals
signal victory(challenger, type)

# Arch constants
const COOLDOWN_TIME = 1.5

enum {IDLE, RINGING}

# Arch variables
var ringer_id = -1

enum {WEAK, MID, HEAVY}

func _ready():
	var error = self.connect('victory', get_parent(), '_on_victory')
	if error: print('Heavyweight victory signal error: %s' % error)

func init(p_id, p_name, p_pos):
	structure_init("Arch", p_id, p_name, p_pos, IDLE, $Gong.get_shape().get_extents().y, $Gong)
	$Anim.play("Idle")

#func _process(__):
#	pass
	
# Reacts to push from player, triggering gong ring
func pushed(player_id, __, __, __):
	
	# if enough time has elapsed since last gong ring
	if state == IDLE:
		
		# set gong as rung for duration of animation
		state = RINGING
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
		state = IDLE
		$Anim.play("Idle")
