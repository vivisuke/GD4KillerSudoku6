extends Node2D

const N_SOLVED_QUEST = 10		# クリア済み問題数

var autoScrolled = false
var panels = []

var QuestPanel = preload("res://quest_panel.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	g.todaysQuest = false
	var txt = ""
	if g.qLevel == 0: txt = "入門"
	elif g.qLevel == 1: txt = "初級"
	elif g.qLevel == 2: txt = "初中級"
	txt += "問題集"
	$TitleBar/Label.text = txt
	g.load_nSolved()
	var ix0 = max(0, g.nSolved[g.qLevel] - N_SOLVED_QUEST)
	for i in range(12):
		var btn = QuestPanel.instantiate()
		panels.push_back(btn)
		if ix0 + i <= g.nSolved[g.qLevel]:		# クリア済み or 非クリア挑戦可能問題
			btn.set_enabled(true)
			if ix0 + i == g.nSolved[g.qLevel]:		# 非クリア挑戦可能問題
				btn.set_icon($LockOpen.texture)
			#btn.solved_set_visible(ix0 + i < g.nSolved[g.qLevel])
		else:
			btn.set_enabled(false)
			btn.set_icon($Locked.texture)
			#btn.solved_set_visible(false)
		btn.set_q_number(ix0 + i + 1)
		$ScrollContainer/VBoxContainer.add_child(btn)
		#btn.connect(StringName("pressed"), self, "_on_QuestButton_pressed")
		btn.connect("pressed", Callable(self, "_on_QuestButton_pressed"))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_QuestButton_pressed(num):
	print("_on_QuestButton_pressed()")
	g.qNumber = num
	get_tree().change_scene_to_file("res://main_scene.tscn")
	pass

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://top_scene.tscn")
