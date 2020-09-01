extends Node2D

# Misc. constants
const PLAYER_NODE = preload("res://Scenes/Player.tscn")
const FLAG_NODE = preload("res://Scenes/Flags.tscn")
const SUMOCIRCLE_NODE = preload("res://Scenes/SumoCircle.tscn")
const SUSHISTAND_NODE = preload("res://Scenes/SushiStand.tscn")
const ARCH_NODE = preload("res://Scenes/Arch.tscn")

const RED = Color(255/255.0, 33/255.0, 50/255.0)
const BLUE = Color(0, 106/255.0, 252/255.0)
const PURPLE = Color(185/255.0, 0, 220/255.0)
const GREEN = Color(0, 140/255.0, 26/255.0)

# Player initializations
const PLAYER_INITS = {
	0: { 'SKIN':'-Red', 'COLOR': RED },
	1: { 'SKIN':'-Blue', 'COLOR': BLUE },
	2: { 'SKIN':'-Purple', 'COLOR': PURPLE },
	3: { 'SKIN':'-Green', 'COLOR': GREEN }
}

# Game constants
const RESPAWN_TIME = 3
const SLAMS_GOAL = 10
const RESTART_TIME = 10

# Sumo circle constants
const CIRCLE_COUNTDOWN_TIME = 10.0

# Sushi constants
const MAX_SUSHI = 10
const COOK_TIME = 5
const SUSHI_CALORIES = 1.0
const CALORIE_THRESHOLDS = [0, 3, 5]

# Game config
var num_sumo_circles = 1
var num_sushi_stands = 2
var num_arches = 1

# Game variables
var player_attributes = {}
var player_stats = {}
var game_won = false
var victory = null
var start_time = null
var end_time = null
var prev_deaths = []

var sushi_count = 0

export var quick_reset = false
export var record_game_stats = true

func _ready():
	randomize()
	
	for id in Global.num_players:
		var new_player = PLAYER_NODE.instance()
		new_player.init(id, 'Player %s' % [id+1], 
						$Stage.PLAYER_SPAWN[id]['POS'],
						PLAYER_INITS[id]['SKIN'], 
						PLAYER_INITS[id]['COLOR'])
		player_attributes[id] = {'name':'Player %s' % [id+1],
									'skin':PLAYER_INITS[id]['SKIN'], 
									'color':PLAYER_INITS[id]['COLOR']}
		player_stats[id] = gen_fresh_stats()
		add_child(new_player)
		
		var new_flag = FLAG_NODE.instance()
		new_flag.init(id, 'Flag %s' % [id+1], 
						$Stage.PLAYER_SPAWN[id]['FLAGS_POS'], 
						PLAYER_INITS[id]['SKIN'])
		add_child(new_flag)
		
	for id in num_sumo_circles:
		var new_circle = SUMOCIRCLE_NODE.instance()
		new_circle.init(id, 'SumoCircle %s' % [id+1], $Stage.SUMOCIRCLE_SPAWN[id]['POS'])
		add_child(new_circle)
		
	for id in num_sushi_stands:
		var new_stand = SUSHISTAND_NODE.instance()
		new_stand.init(id, 'SushiStand %s' % [id+1], $Stage.SUSHISTAND_SPAWN[id]['POS'])
		add_child(new_stand)
	
	for id in num_arches:
		var new_arch = ARCH_NODE.instance()
		new_arch.init(id, 'Arch %s' % [id+1], $Stage.ARCH_SPAWN[id]['POS'])
		add_child(new_arch)
	
	start_time = OS.get_ticks_msec()
		
func _on_victory(winner_id, type):
	# If game has not been won yet, indicate victory
	if !game_won:
		victory = type
		player_stats[winner_id]['winner'] = true
		
		var message = ''
		if type == 'SUMO_CIRCLE':
			message = '%s is the Sumo Circle Champion!' % player_attributes[winner_id]['name']
		elif type == 'SLAMS':
			message = '%s is the Sumo Slam Champion!' % player_attributes[winner_id]['name']
		elif type == 'HEAVYWEIGHT':
			message = '%s is the Sumo Heavyweight Champion!' % player_attributes[winner_id]['name']
			
		$Display/Announcement.add_color_override("font_color", player_attributes[winner_id]['color'])
		$Display/Announcement.set_text(message)
		game_won = true
		end_time = OS.get_ticks_msec()
		
		# if record_game_stats, save session player stats as json
		if record_game_stats:
			gen_session_save_file()
		
	# if quick_reset, restart game after reset time
	if quick_reset:
		# Wait for timeout
		yield(get_tree().create_timer(RESTART_TIME), "timeout") 
		var error = get_tree().reload_current_scene()
		if error: print('Reload current scene error: %s' % error)
		
# Returns whether death is to be recorded
func valid_death(time_of_death, player, attacker):
	
	if prev_deaths:
		var prev_time_of_death = prev_deaths[-1][0]
		var prev_victim = prev_deaths[-1][1]
		var prev_attacker = prev_deaths[-1][2]
		
		# If slams occurred within a short window, check if slam is a double count
		if time_of_death - prev_time_of_death < RESPAWN_TIME:
		
			# If same player signaled death twice, do not count
			if player == prev_victim:
				return false
				
			# If players signaled as slamming each other, do not count
			if attacker == prev_victim and prev_attacker == player:
				return false
		
	return true
	
# Updates player stats after death and respawns player that died (after wait)
func _on_player_death(player, attacker_id=-1):
	
	var time_of_death = OS.get_ticks_msec() / 1000.0
		
	# Verify that death signal is not a double count
	if valid_death(time_of_death, player.id, attacker_id):
		
		# Increment player's death tracker
		player_stats[player.id]['deaths'] += 1
		
		# Set player weight back to zero
		player_stats[player.id]['calories'] = 0
		
		# If revenge slam, record
		if prev_deaths:
			var prev_victim = prev_deaths[-1][1]
			var prev_attacker = prev_deaths[-1][2]
			
			if attacker_id == prev_victim and prev_attacker == player.id:
				player_stats[attacker_id]['revenge_slams'] += 1
		
		# stores details of death
		prev_deaths += [[time_of_death, player.id, attacker_id]]
		
		# If was killed, increment attacker's slams
		if attacker_id >= 0:
			player_stats[attacker_id]['slams'] += 1
			
			# If attacker crossed victory threshold, trigger slam victory
			if player_stats[attacker_id]['slams'] == SLAMS_GOAL:
				_on_victory(attacker_id, 'SLAMS')
			
			var flags = get_node("Flag %s" % [attacker_id+1])
			flags.raise_flag( player_stats[attacker_id]['slams'])
	
		# Remove player from tree and respawn after set wait time
		var respawned = PLAYER_NODE.instance()
		respawned.init(player.id, 
						player.name, 
						$Stage.PLAYER_SPAWN[player.id]['POS'],
						player.skin, 
						player.color)
		player.queue_free()
		yield(get_tree().create_timer(RESPAWN_TIME), "timeout")
		add_child(respawned)
		
# If sushi cap has not been reached, cook sushi
func order_sushi():
	if sushi_count < MAX_SUSHI:
		
		var stand = get_node('SushiStand %s' % ((randi() % num_sushi_stands) + 1) )
		
		if !stand.destroyed:
			stand.cook_sushi()
	else:
		yield(get_tree().create_timer(COOK_TIME), "timeout")
		order_sushi()
		
# Once sushi is spawned, increment count
func _on_sushi_cooked():
	sushi_count += 1
	order_sushi()

func gen_fresh_stats():
	return {
		'winner':false,
		'deaths':0, 
		'slams':0,
		'revenge_slams':0,
		'calories':0,
		'total_calories':0,
		'challenges':0,
		'challenge_time':0,
		'gong_rings':0,
		'double_jumps':0,
		'dashes':0,
		'pushes':0,
		'pushed':0,
		'blocks':0,
		'blocked':0,
		'taunts':0,
		'taunted':0
	}
	
#func eval_performances():
#	var titles = {
#		'to_hell_and_back':-1,    # Most deaths
#		'no_time_to_die':-1,      # Least deaths
#
#		'up_for_a_challenge':-1,  # Most challenges
#
#		'hungry_for_a_win':-1,    # Most calories
#
#		'block_party':-1,         # Most blocks
#		'shooters_shoot':-1,      # Most times getting blocked
#
#		'push_comes_to_shove':-1, # Most pushes
#		'pushover':-1,            # Most times getting pushed
#
#		'revenge_is_sweet':-1,    # Most revenge slams
#
#		'rings_a_bell':-1,        # Most gong rings
#
#		'race_to_the_finish':-1,  # Most dashes
#		'slow_and_steady':-1      # Least dashes
#	}
	
	

func gen_session_save_file():
	var timestamp = OS.get_datetime()
	var path = './Saves'
	ensure_path(path)
	var filename = 'session_stats_d%s_h%s_m%s.json' % [timestamp['day'], 
														timestamp['hour'], 
														timestamp['minute']]
	var file = File.new()
	var error = file.open('%s/%s' % [path, filename], File.WRITE)
	if error: print('Save file writing error: %s' % error)

	var session_stats = {}

	var game = {}
	game['time'] = (end_time - start_time) / 1000.0
	game['victory'] = victory

	for id in Global.num_players:
		player_attributes[id]['stats'] = player_stats[id]
		player_attributes[id]['color'] = str(player_attributes[id]['color']).replace(",", "-")

	session_stats['game'] = game
	session_stats['players'] = player_attributes

	file.store_line(beautify_json(to_json(session_stats)))
	file.close()
	
func ensure_path(path):
	var dir = Directory.new()
	if( !dir.dir_exists(path) ):
		var error = dir.make_dir_recursive(path)
		if error: print('Directory creation error: %s' % error)
	
static func beautify_json(json, spaces = 0):
	var error_message = validate_json(json)
	if not error_message.empty():
		return error_message
	
	# Remove pre-existing formating
	json = json.replace(" ", "")
	json = json.replace("\n", "")
	json = json.replace("\t", "")
	
	json = json.replace("{", "{\n")
	json = json.replace("}", "\n}")
	json = json.replace("{\n\n}", "{}") # Fix newlines in empty brackets
	json = json.replace("[", "[\n")
	json = json.replace("]", "\n]")
	json = json.replace("[\n\n]", "[]") # Same as above
	json = json.replace(":", ": ")
	json = json.replace(",", ",\n")
	
	var indentation = ""
	if spaces > 0:
		for i in spaces:
			indentation += " "
	else:
		indentation = "\t"
	
	var begin
	var end
	var bracket_count
	for i in [["{", "}"], ["[", "]"]]:
		begin = json.find(i[0])
		while begin != -1:
			end = json.find("\n", begin)
			bracket_count = 0
			while end != - 1:
				if json[end - 1] == i[0]:
					bracket_count += 1
				elif json[end + 1] == i[1]:
					bracket_count -= 1
				
				# Move through the indentation to see if there is a match
				while json[end + 1] == indentation:
					end += 1
					
					if json[end + 1] == i[1]:
						bracket_count -= 1
				
				if bracket_count <= 0:
					break
				
				end = json.find("\n", end + 1)
			
			# Skip one newline so the end bracket doesn't get indented
			end = json.rfind("\n", json.rfind("\n", end) - 1)
			while end > begin:
				json = json.insert(end + 1, indentation)
				end = json.rfind("\n", end - 1)
			
			begin = json.find(i[0], begin + 1)
	
	return json
		
