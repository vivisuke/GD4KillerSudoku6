extends Node2D


const N_BUTTONS = 6
const LVL_BEGINNER = 0
const LVL_EASY = 1
const LVL_NORMAL = 2

var Board6x6 = preload("res://scripts/Board6x6.gd")

var buttons = []
#onready var g = get_node("/root/Global")

func _ready():
	var node = $TestNode2D
	print($TestNode2D.foo)
	#var bd = Board6x6.new()
	##bd.gen_ans()
	##bd.print_ans_num()
	##bd.print_cells()
	#bd.gen_quest(LVL_BEGINNER, "a0")
	#bd.print_cages()
	#bd.print_cages_ex()
	#bd.print_cells()
	#print("nSpaces = ", bd.nSpaces)
	#bd.print_ans_num()
	#var diff = bd.calc_difficulty()
	#print("diff = ", diff)
	#var bd2 = Board6x6.new()
	#bd2.dupcopy(bd)
	#
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
	for i in range(N_BUTTONS):
		buttons.push_back(get_node("Button%d" % i))
	for i in range(N_BUTTONS):
		var n = g.stats[i]["NSolved"] if g.stats[i].has("NSolved") else 0
		buttons[i].get_node("NSolvedLabel").text = "クリア回数: %d" % n
		var txt = "平均タイム: "
		if n == 0:
			txt += "N/A"
		else:
			var avg : int = int(g.stats[i]["TotalSec"] / n)
			txt += g.sec_to_MSStr(avg)
		buttons[i].get_node("AveTimeLabel").text = txt
		txt = "最短タイム: "
		if g.stats[i].has("BestTime"):
			txt += g.sec_to_MSStr(g.stats[i]["BestTime"])
		else:
			txt += "N/A"
		buttons[i].get_node("BestTimeLabel").text = txt
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
