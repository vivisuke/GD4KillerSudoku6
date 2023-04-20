extends Node2D


const N_BUTTONS = 6

var buttons = []
#onready var g = get_node("/root/Global")

func _ready():
	#print(g.yesterday_string())
	g.todaysQuest = false
	g.load_environment()
	if !g.env.has(g.KEY_LOGIN_DATE) || g.env[g.KEY_LOGIN_DATE] != g.today_string():
		g.env[g.KEY_LOGIN_DATE] = g.today_string()
		g.env[g.KEY_N_COINS] += g.DAYLY_N_COINS
		g.save_environment()
	$CoinButton/NCoinLabel.text = str(g.env[g.KEY_N_COINS])
	g.load_stats()
	#
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

func to_LevelScene(qLevel):
	#print($LineEdit.text)
	g.qNumber = 0
	g.qLevel = qLevel
	g.qName = ""
	g.qRandom = false
	g.todaysQuest = false
	get_tree().change_scene_to_file("res://level_scene.tscn")
func _on_button_3_pressed():
	to_LevelScene(0)
func _on_button_4_pressed():
	to_LevelScene(1)
func _on_button_5_pressed():
	to_LevelScene(2)
func _on_button_6_pressed():
	get_tree().change_scene_to_file("res://todays_quest.tscn")
