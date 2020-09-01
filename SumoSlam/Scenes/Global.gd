extends Node

# warning-ignore:unused_class_variable
var num_players = 4

enum {ENVIRONMENT, PLAYERS, ITEMS, STRUCTURES}

func set_entity_mask_bits(entity, layers, values):
	
	if typeof(layers) == TYPE_STRING: layers = [layers]
	
	for i in range(len(layers)):
		
		var layer
		match layers[i]:
			"Environment":
				layer = ENVIRONMENT
			"Players":
				layer = PLAYERS
			"Items":
				layer = ITEMS
			"Structures":
				layer = STRUCTURES
				
		var value = values if typeof(values) == TYPE_BOOL else values[i]
				
		entity.set_collision_mask_bit(layer, value)

func collision_momentum(velocity, giver, receiver, transfer_factor=2):

	var rel_scale = float(giver) / receiver
	var momentum = velocity / transfer_factor
	
	return rel_scale * momentum
	
func sufficient_margin(prev_time, buffer):
	
	return OS.get_system_time_msecs() - prev_time > buffer
	