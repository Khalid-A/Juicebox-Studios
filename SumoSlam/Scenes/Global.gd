extends Node

# warning-ignore:unused_class_variable
var num_players = 4

func collision_momentum(velocity, giver, receiver, transfer_factor=2):

	var rel_scale = float(giver) / receiver
	var momentum = velocity / transfer_factor
	
	return rel_scale * momentum