extends Node2D


func _ready():
	$DateLabel.text = g.today_string()
func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://top_scene.tscn")
func to_MainScene(qLevel):
	g.qLevel = qLevel
	g.qRandom = false
	g.qNumber = 0
	g.qName = g.today_string()
	get_tree().change_scene_to_file("res://main_scene.tscn")
func _on_button_0_pressed():
	to_MainScene(0)
func _on_button_1_pressed():
	to_MainScene(1)
func _on_button_2_pressed():
	to_MainScene(2)
