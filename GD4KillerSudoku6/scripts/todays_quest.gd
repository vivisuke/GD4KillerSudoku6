extends Node2D


func _ready():
	$DateLabel.text = g.today_string()
func _process(delta):
	pass


func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://top_scene.tscn")
