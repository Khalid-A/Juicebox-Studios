extends Node2D

const GAME_PATH = "res://Scenes/Game.tscn"

func _ready():
	$NumPlayerButtons.visible = false
	get_node("NumPlayerButtons/2PlayerButton").disabled = true
	get_node("NumPlayerButtons/3PlayerButton").disabled = true
	get_node("NumPlayerButtons/4PlayerButton").disabled = true

func start_game():
	if get_tree().change_scene(GAME_PATH) != OK:
		print("Failed to change scene to Game.tscn")

func _on_PlayButton_pressed():
	$PlayButton.visible = false
	$PlayButton.disabled = true
	
	$NumPlayerButtons.visible = true
	get_node("NumPlayerButtons/2PlayerButton").disabled = false
	get_node("NumPlayerButtons/3PlayerButton").disabled = false
	get_node("NumPlayerButtons/4PlayerButton").disabled = false
	
	get_node("NumPlayerButtons/2PlayerButton").grab_focus()

func _on_2PlayerButton_pressed():
	Global.num_players = 2
	start_game()

func _on_3PlayerButton_pressed():
	Global.num_players = 3
	start_game()

func _on_4PlayerButton_pressed():
	Global.num_players = 4
	start_game()
