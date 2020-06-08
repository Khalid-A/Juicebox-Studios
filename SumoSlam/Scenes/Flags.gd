extends Node2D

const MAX_FLAGS = 3
const SLAMS_PER_FLAG = 3

# Flag identifiers
var id
var skin
var flags_raised

func is_class(_class): 
	return _class == "Flag"

func get_class(): 
	return "Flag"

func init(p_id, p_name, p_pos, p_skin):
	self.id = p_id
	self.skin = p_skin
	self.name = p_name
	self.position = p_pos
	for child in get_children():
		child.play("0" + p_skin)
	flags_raised = 0
		
func raise_flag(slams):
	
	flags_raised = 1 + ((slams - 1) / SLAMS_PER_FLAG)
	
	if flags_raised <= MAX_FLAGS:
		
		for f in range(flags_raised):
			
			var count = SLAMS_PER_FLAG if flags_raised - 1 > f else slams - (f * SLAMS_PER_FLAG)
			
			get_node("Flag%s" % f).play("%s" % count + skin)
		