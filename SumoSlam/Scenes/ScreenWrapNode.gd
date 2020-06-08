extends Node2D

# Declare three Axis types
const AXIS = {
	HORIZONTAL = "x",
	VERTICAL = "y",
	BOTH = "x&y"
}

const ANIMATED_SPRITE = 0

# Change this according to preferences
var horizontalWrap = false
var verticalWrap = false
var wrapArea = null
var instancePath = null

# If the horizontal flag is set, action the decision
func setHorizontalWrap(flag):
	horizontalWrap = flag

# If the vertical flag is set, action the decision
func setVerticalWrap(flag):
	verticalWrap = flag
	
var parent
var spriteSize
var halfSpriteSize
	
func _ready():
	parent = get_parent()
	spriteSize = Vector2(32.0, 32.0)
	halfSpriteSize = spriteSize / 2
	setHorizontalWrap(horizontalWrap)
	setVerticalWrap(verticalWrap)
	wrapArea = get_viewport_rect()

# Define the process to process the wrap on this Sprite, every frame
#
# Unfortunately, I would like to extend the Sprite Class and override the
# position variable or set_position function, but currently, Godot Engine
# does not allow it. So, instead of only wrapping when the Sprite is moved,
# we are forced to check EVERY frame; which requires more calculations!
func _process(__):
	synchronizeAll()
	# Only wrap if an area is defined otherwise stop all processing
	if wrapArea != null:
		wrapHorizontally()
		wrapVertically()
		checkForHorizontalAndVerticalWrap()
	else:
		set_process(false)

func synchronizeAll():
	for child in get_children():
		child.synchronize(parent)

# Check whether Horizontal wrapping is configured and do it!
func wrapHorizontally():
	if horizontalWrap:
		applyWrap(AXIS.HORIZONTAL)

# Check whether vertical wrapping is configured and do it!
func wrapVertically():
	if verticalWrap:
		applyWrap(AXIS.VERTICAL)

# Check whether the 'special case' is detected. I.E. If the sprite is
# to be wrapped horizontally and vertically, IT MUST be in the corner, 
# therefore we MUST add the third diagnal corner!
func checkForHorizontalAndVerticalWrap():
	if has_node(AXIS.HORIZONTAL) && has_node(AXIS.VERTICAL):
		addMirrorForBothAxis()
	else:
		removeMirror(AXIS.BOTH)

# This checks for two cases on each border
#
# 1. If the parent has started to wrap, then we need to create a copy
# 2. If the parent has gone off screen (completed wrapping), then we need to
#    remove the copy and reposition the parent over the copy

func applyWrap(axis):
	# Check if the parent has gone off the screen (left or top)
	if parent.position[axis] <= wrapArea.position[axis] - halfSpriteSize[axis]:
		completeWrap(axis, wrapArea.size[axis])
	# Check if the parent has started to wrap (left or top)
	elif parent.position[axis] <= wrapArea.position[axis] + halfSpriteSize[axis]:
		mirrorWrap(axis, wrapArea.size[axis])
	# Check if the parent has gone off the screen (right or bottom)
	elif parent.position[axis] >= wrapArea.position[axis] + wrapArea.size[axis] + halfSpriteSize[axis]:
		completeWrap(axis, -wrapArea.size[axis])
	# Check if the parent has started to wrap (right or bottom)
	elif parent.position[axis] >= wrapArea.position[axis] + wrapArea.size[axis] - halfSpriteSize[axis]:
		mirrorWrap(axis, -wrapArea.size[axis])
	# Check if the parent is within screen and has a mirror 
	elif has_node(parent.name + "_" + axis):
		removeMirror(axis)

# Move the Sprite to the opposite side and delete of the copy 
func completeWrap(axis, gap):
	parent.position[axis] += gap
	removeMirror(axis)

# If the copy doesn't already exist (we use the node name as 'axis') then
# create a mirror copy of this Sprite and add it as a child! A child, so that
# we can look it up and only ever have THREE children per Sprite! 
# i.e. Horizontal, Vertical and Diagnal copies!
func mirrorWrap(axis, gap):
	if !has_node(parent.name + "_" + axis):
		var mirrorOffset = Vector2(0, 0)
		mirrorOffset[axis] = gap
		addMirror(axis, mirrorOffset)

# Make a copy of the Sprite and add it as a child
# Because it is to be a child, set the position to 0 x 0 and use the offset
# to positon it! By doing this, as the Sprite moves, so will it's child, 
# thereby making the copy to move in synch to it!
#
# Note: The name is important, because we use it to determine if it already
#       exists and for removing it too!
func addMirror(axis, mirrorOffset):
	var mirrorPlayer = load(instancePath).instance()
	mirrorPlayer.name = parent.name + "_" + axis
	mirrorPlayer.translate(mirrorOffset)
	add_child(mirrorPlayer)

# The special case to create the copy in a diagnal of the Sprite, if both
# Horizontal and Vertical positions are set.
# 
# Create an empty Vector2 and then copy in both the Horizontal and Vertical
# offsets, by doing so, you end up with the opposite corner! The beauty of
# mathematics.
func addMirrorForBothAxis():
	if !has_node(AXIS.BOTH):
		var mirrorOffset = Vector2(0, 0)
		mirrorOffset = get_node(AXIS.HORIZONTAL).offset
		mirrorOffset += get_node(AXIS.VERTICAL).offset
		addMirror(AXIS.BOTH, mirrorOffset)

# Finally, remove the node if it is a child 
func removeMirror(axis):
	if has_node(parent.name + "_" + axis):
		get_node(parent.name + "_" + axis).queue_free()
