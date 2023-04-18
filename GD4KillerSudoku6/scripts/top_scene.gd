extends Node2D


const N_BUTTONS = 6

var buttons = []
#onready var g = get_node("/root/Global")

func _ready():
	pass # Replace with function body.


func _process(delta):
	pass

func to_MainScene(qLevel):
	print($LineEdit.text)
	g.qLevel = qLevel
	g.qName = $LineEdit.text
	g.qRandom = $LineEdit.text == ""
	g.qNumber = 0
	g.todaysQuest = false
	get_tree().change_scene_to_file("res://main_scene.tscn")
func _on_button_0_pressed():
	to_MainScene(0)
func _on_button_1_pressed():
	to_MainScene(1)
func _on_button_2_pressed():
	to_MainScene(2)


func _on_button_6_pressed():
	get_tree().change_scene_to_file("res://todays_quest.tscn")
