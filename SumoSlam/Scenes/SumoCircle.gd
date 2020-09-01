extends Structure

# Sumo circle signals
signal victory(challenger_id, type)

# Progress Bar constants
const WHITE = Color(1, 1, 1)
const BAR_POSITION = Vector2(-60, 35)
const BAR_MAX_SIZE = Vector2(120.0, 6.0)

enum {IN_PROGRESS, WON}

# Sumo circle variables
var challenger_id = -1
var challenge_start = null
var arena_occupants = []
var exit_time = null
var exit_time_multiplier = 1

func _ready():
	var error = self.connect('victory', get_parent(), '_on_victory')
	if error: print('Sumo circle victory signal error: %s' % error)
	reset_challenge()
	
func init(p_id, p_name, p_pos):
	structure_init("SumoCircle", p_id, p_name, p_pos, IN_PROGRESS, 1, $Platform)
	$CircleAnim.play("Unoccupied")
	
func _process(__):
	if challenger_id >= 0 and state == IN_PROGRESS:
		update_challenge_status()
#		$Indicator.visible = true
#		$Indicator.set_text(str(ceil($Countdown.time_left)))
		
		# Update progress bar
		$ProgressBar.visible = true
		var percentage = $Countdown.time_left / get_parent().CIRCLE_COUNTDOWN_TIME
		$ProgressBar.rect_size.x = ceil(BAR_MAX_SIZE.x * percentage)
		$ProgressBar.rect_position.x = BAR_POSITION.x + ((1 - percentage) * BAR_MAX_SIZE.x / 2)

	else:
#		$Indicator.visible = false
		$ProgressBar.visible = false

# Tracks player that enters arena
func _on_player_entered(body):
	
	if !body.is_class("Player"): return
	
	if challenger_id == -1:
		challenger_id = body.id
		challenge_start = OS.get_ticks_msec()
		get_parent().player_stats[challenger_id]['challenges'] += 1
#		$Indicator.add_color_override("font_color", body.color)
		$ProgressBar.color = get_parent().player_attributes[challenger_id]['color']
	arena_occupants += [body.id]

# Ends tracking of player that leaves arena
func _on_player_exited(body):
	
	if !body.is_class("Player"): return
	
	arena_occupants.erase(body.id)

# Ends competition for sumo circle
func _on_challenge_won():
	if state == IN_PROGRESS:
		state = WON
		get_parent().player_stats[challenger_id]['challenge_time'] += (OS.get_ticks_msec() - challenge_start) / 1000.0
	#	$Indicator.visible = false
		$ProgressBar.rect_size.x = 0
		emit_signal('victory', challenger_id, 'SUMO_CIRCLE')
	
func reset_progress_bar():
	$ProgressBar.color = WHITE
	$ProgressBar.rect_position.x = BAR_POSITION.x
	$ProgressBar.rect_position.y = BAR_POSITION.y
	$ProgressBar.rect_size.x = BAR_MAX_SIZE.x
	$ProgressBar.rect_size.y = BAR_MAX_SIZE.y
	
# Resets sumo circle competition
func reset_challenge():
	if challenger_id >= 0:
		get_parent().player_stats[challenger_id]['challenge_time'] += (OS.get_ticks_msec() - exit_time) / 1000.0
		
	challenger_id = -1
	challenge_start = null
#	$Indicator.visible = false
	$Countdown.set_paused(true)
	$Countdown.start(get_parent().CIRCLE_COUNTDOWN_TIME)
	reset_progress_bar()
	
	# If previous challenger failed, 
	# longest remaining occupier becomes challenger
	if len(arena_occupants) > 0:
		challenger_id = arena_occupants[0]
		challenge_start = OS.get_ticks_msec()
		get_parent().player_stats[challenger_id]['challenges'] += 1
#		$Indicator.add_color_override("font_color", challenger.color)
		$ProgressBar.color = get_parent().player_attributes[challenger_id]['color']
		
# Rollback countdown by time spent away from circle
func rollback_countdown():
	var time_out = (OS.get_ticks_msec() - exit_time) / 1000.0
	var updated_countdown = $Countdown.time_left + (time_out * exit_time_multiplier)
	$Countdown.start(updated_countdown)
	
# Update status of sumo circle victory
func update_challenge_status():
	
	# If challenger exited arena, rollback countdown accordingly
	if exit_time != null:
		rollback_countdown()
		if $Countdown.time_left > get_parent().CIRCLE_COUNTDOWN_TIME: 
			reset_challenge()
		
	# Challenger in circle
	if challenger_id in arena_occupants:
		
		# Challenger not alone in circle
		if len(arena_occupants) > 1:
			$Countdown.set_paused(true)
			
		# Challenger alone in circle
		else:
			$Countdown.set_paused(false)
			
		exit_time = null
		
	# Challenger not in circle
	else:
		$Countdown.set_paused(true)
		exit_time = OS.get_ticks_msec()
		
		# If challenger not in circle and opponent is, 
		# time counts down twice as fast
		if len(arena_occupants) > 0:
			exit_time_multiplier = 2
		else:
			exit_time_multiplier = 1
		
