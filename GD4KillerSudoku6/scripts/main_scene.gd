extends Node2D

enum {
	HORZ = 1,
	VERT,
	BOX,
	CELL,
}
enum {
	CAGE_SUM = 0,			# ケージ内数字合計
	CAGE_IX_LIST,			# ケージ内セル位置配列
}
enum {
	#IX_CAGE_COLOR = 0,		# ケージ背景色、0, 1, 2, 3
	IX_CAGE_TOP_LEFT = 0,	# ケージ左上位置
	IX_CAGE_N,				# ケージ内数字数
	IX_CAGE_SUM,			# ケージ内数字合計
	IX_CAGE_BITS,			# ケージ内数字ビット論理和
	#IX_CAGE_IX_LIST,		# ケージに含まれるセルIXのリスト
}

const N_COLOR = 4			# ケージ色種数
const CAGE_N_NUM_MAX = 4	# ケージ最大セル数
const N_VERT = 6
const N_HORZ = 6
const N_CELLS = N_HORZ * N_VERT
const N_BOX_VERT = 2
const N_BOX_HORZ = 3
const CELL_WIDTH = 81
const CELL_WIDTH3 = CELL_WIDTH/3
const CELL_WIDTH4 = CELL_WIDTH/4
const BIT_1 = 1
const BIT_2 = 1<<1
const BIT_3 = 1<<2
const BIT_4 = 1<<3
const BIT_5 = 1<<4
const BIT_6 = 1<<5
const BIT_7 = 1<<6
const BIT_8 = 1<<7
const BIT_9 = 1<<8
const ALL_BITS = (1<<N_HORZ) - 1
const BIT_MEMO = 1<<10
const TILE_NONE = -1
const TILE_CURSOR = 0					# カーソル（薄ピンク）
const TILE_EMPHASIZE = 1				# 強調カーソル（薄黄色）
const COLOR_INCORRECT = Color.RED
const COLOR_DUP = Color.RED
const COLOR_CLUE = Color.BLACK
const COLOR_INPUT = Color.BLACK
const UNDO_TYPE_CELL = 0		# セル数字入力
const UNDO_TYPE_MEMO = 1		# メモ数字反転
const UNDO_TYPE_AUTO_MEMO = 2	# 自動メモ
const UNDO_TYPE_DEL_MEMO = 3	# メモ削除
const UNDO_ITEM_TYPE = 0
const UNDO_ITEM_IX = 1
const UNDO_ITEM_NUM = 2			# for メモ数字
const UNDO_ITEM_OLD = 2			# for セル数字
const UNDO_ITEM_NEW = 3			# for セル数字
const UNDO_ITEM_MEMOIX = 4		# メモ数字反転位置リスト
const UNDO_ITEM_MEMO = 5		# 数字を入れた位置のメモ数字（ビット値）
const UNDO_ITEM_MEMO_LST = 1
const NUM_FONT_SIZE = 40
const MEMO_FONT_SIZE = 20
const LVL_BEGINNER = 0
const LVL_EASY = 1
const LVL_NORMAL = 2
const AUTO_MEMO_N_COINS = 3				# 自動メモ消費コイン数

const CAGE_TABLE = [
	[	# for 2セルケージ
		0b000000, 0b000000, 0b000011, 0b000101, 0b001111,	# for 1, 2, ... 5
		0b011011, 0b111111, 0b110110, 0b111100, 0b101000, 	# for 6, 7, ... 10
		0b110000, 											# for 11
	],
	[	# for 3セルケージ
		0b000000, 0b000000, 0b000000, 0b000000, 0b000000,	# for 1, 2, ... 5
		0b000111, 0b001011, 0b011111, 0b111111, 0b111111,	# for 6, 7, ... 10
		0b111111, 0b111111, 0b111110, 0b110100, 0b111000,	# for 11, 12, ... 15
	],
	[	# for 4セルケージ
		0b000000, 0b000000, 0b000000, 0b000000, 0b000000,	# for 1, 2, ... 5
		0b000000, 0b000000, 0b000000, 0b000000, 0b001111,	# for 6, 7, ... 10
		0b010111, 0b111111, 0b111111, 0b111111, 0b111111,	# for 11, 12, ... 15
		0b111111, 0b111111, 0b111111, 0b111010, 0b111100,	# for 16, 17, 18
	],
]

var qix                 	# 問題番号 [0, N]
var qID                 	# 問題ID
var qSolved = false     	# 現問題をクリア済みか？
#var qSolvedStat = false     # 現問題をクリア状態か？
#var elapsedTime = 0.0   	# 経過時間（単位：秒）
var symmetric = true		# 対称形問題
var qCreating = false		# 問題生成中
var solvedStat = false		# クリア済み状態
var paused = false			# ポーズ状態
var sound = true			# 効果音
var menuPopuped = false
var hint_showed = false
var memo_mode = false		# メモ（候補数字）エディットモード
var in_button_pressed = false	# ボタン押下処理中
var hint_ix = -1			# ヒントを入れる箇所
var hint_count_down = 0.0	# 0.0より大きい：ヒント表示カウントダウン中
var confetti_count_down = 0.0	# 0.0より大きい：紙吹雪表示中
var hint_next_pos			# 次ボタン位置
var hint_next_pos0			# 次ボタン初期位置
var hint_next_vy			# 次ボタン速度
var saved_cell_data = []

#var hint_next_scale = 1.0	# ヒント次ボタン表示スケール
#var hint_num				# ヒントで確定する数字、[1, 9]
var hint_numstr				# ヒントで確定する数字、[1, 9]
#var hint_ix = 0				# 0, 1, 2, ...
var hint_texts = []			# ヒントテキスト配列
#var restarted = false
var saved_time
var nEmpty = 0				# 空欄数
var nDuplicated = 0			# 重複、合計不正数字数
#var optGrade = -1			# 問題グレード、0: 入門、1:初級、2:ノーマル（初中級）
var diffculty = 0			# 難易度、フルハウス: 1, 隠れたシングル: 2, 裸のシングル: 10pnt？
var num_buttons = []		# 各数字ボタンリスト [0] -> 削除ボタン、[1] -> Button1, ...
var num_used = []			# 各数字使用数（手がかり数字＋入力数字）
var cur_num = -1			# 選択されている数字ボタン、-1 for 選択無し
var cur_cell_ix = -1		# 選択されているセルインデックス、-1 for 選択無し
var input_num = 0			# 入力された数字
var nRemoved
var nAnswer = 0				# 解答数

var cage_labels = []		# ケージ合計数字用ラベル配列
var clue_labels = []		# 手がかり数字用ラベル配列
var input_labels = []		# 入力数字用ラベル配列
var ans_num = []			# 解答の各セル数値、1～N_HORZ
#var ans_bit = []			# 解答の各セル数値（0 | BIT_1 | BIT_2 | ... | BIT_9）
var cell_bit = []			# 各セル数値（0 | BIT_1 | BIT_2 | ... | BIT_9）
var quest_cages = []		# クエストケージリスト配列、要素：[sum, ix1, ix2, ...]
var cage_list = []			# ケージリスト配列、要素：IX_CAGE_XXX
var cage_ix = []			# 各セルのケージリスト配列インデックス
var candidates_bit = []		# 入力可能ビット論理和
var line_used = []			# 各行の使用済みビット
var column_used = []		# 各カラムの使用済みビット
var box_used = []			# 各3x3ブロックの使用済みビット
var memo_labels = []		# メモ（候補数字）用ラベル配列（２次元）
var memo_text = []			# ポーズ復活時用ラベルテキスト配列（２次元）
var shock_wave_timer = -1
var undo_ix = 0
var undo_stack = []			# 要素：[ix old new]、old, new は 0～9 の数値、0 for 空欄

var rng = RandomNumberGenerator.new()
var FallingChar = load("res://falling_char.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	g.qLevel = LVL_NORMAL
	init_labels()
	g.load_stats()
	#
	cell_bit.resize(N_CELLS)
	ans_num.resize(N_CELLS)
	#ans_bit.resize(N_CELLS)
	candidates_bit.resize(N_CELLS)
	cage_ix.resize(N_CELLS)
	line_used.resize(N_HORZ)
	column_used.resize(N_HORZ)
	box_used.resize(N_HORZ)
	memo_text.resize(N_CELLS)
	num_used.resize(N_HORZ + 1)		# +1 for 0
	#
	clear_cell_cursor()
	#
	num_buttons.push_back($DeleteButton)
	for i in range(N_HORZ):
		num_buttons.push_back(get_node("HBC%d/Button%d" % [i/3+1, (i+1)]))
	#
	gen_ans()
	#gen_cages()
	gen_quest()
	$CanvasLayer/ColorRect.material.set("shader_param/size", 0)
	pass # Replace with function body.
func gen_qName():
	g.qRandom = true
	g.qName = ""
	rng.randomize()
	for i in range(15):
		var r = rng.randi_range(0, 10+26-1)
		if r < 10: g.qName += str(r+1)
		else: g.qName += "%c" % (r - 10 + 0x61)		# 0x61 is 'a'
func gen_quest():
	# undone: 問題集以外の場合対応
	#if g.todaysQuest:		# 今日の問題の場合
	#	g.qLevel += 1
	#	if g.qLevel > 2: g.qLevel = 0
	#elif g.qNumber == 0:		# 問題自動生成の場合
	#	g.qRandom = true		# 
	#	gen_qName()
	#else:					# 問題集の場合
	#	g.qNumber += 1
	#	g.qName = "%06d" % g.qNumber
	if g.qNumber != 0:	# 問題集の場合
		$NextButton.disabled = g.qNumber > g.nSolved[g.qLevel]
	elif !g.todaysQuest:		# ランダム生成の場合
		if g.qName == "":
			##gen_qName()
			g.qName = "0002"
			$TitleBar/Label.text = titleText()
	var stxt = g.qName+str(g.qLevel)
	if g.qNumber != 0: stxt += "Q"
	seed(stxt.hash())
	rng.set_seed(stxt.hash())
	while true:
		gen_ans()
		gen_cages()
		if g.qLevel == LVL_BEGINNER:
			if count_n_cell_cage(1) < 8:
				continue			# 再生成
		#	#split_2cell_cage()		# 1セルケージ数が４未満なら２セルケージを分割
		#el
		if g.qLevel == LVL_NORMAL:
			merge_2cell_cage()
			#if count_n_cell_cage(3) <= 3:
			#merge_2cell_cage()
		#print_cages()
		#gen_cages_3x2()		# 3x2 単位で分割
		#break
		#ans_bit = cell_bit.duplicate()
		#break
		if is_proper_quest():
			break
	#print_ans()
	fill_1cell_cages()
	update_cages_sum_labels()
	solvedStat = false
	g.elapsedTime = 0.0
	#ans_bit = cell_bit.duplicate()
	#print_ans()
	print_ans_num()
func fill_1cell_cages():
	for ci in range(cage_list.size()):
		var cage = cage_list[ci]
		if cage[CAGE_IX_LIST].size() == 1:
			var ix = cage[CAGE_IX_LIST][0]
			cell_bit[ix] = num_to_bit(cage[CAGE_SUM])
			input_labels[ix].text = str(cage[CAGE_SUM])
func count_n_cell_cage(n):
	var cnt = 0
	for i in range(cage_list.size()):
		if cage_list[i][CAGE_IX_LIST].size() == n: cnt += 1
	return cnt
func find_2cell_cage():		# 2セルケージを探す
	while true:
		var ix = rng.randi_range(0, cage_list.size() - 1)
		if cage_list[ix][CAGE_IX_LIST].size() == 2:
			return ix
func split_2cell_cage():		# 1セルケージ数が４未満なら２セルケージを分割
	if count_n_cell_cage(1) >= 4: return
	var cix = find_2cell_cage()		# 2セルケージを探す
	var cage = cage_list[cix]
	var ix2 = cage[CAGE_IX_LIST][1]		# ２番めの要素
	cage_ix[ix2] = cage_list.size()
	var t = [bit_to_num(cell_bit[ix2]), [ix2]]
	cage_list.push_back(t)
	var ix1 = cage[CAGE_IX_LIST][0]		# 1番めの要素
	cage = [bit_to_num(cell_bit[ix1]), [ix1]]
	#update_cages_sum_labels()
	cage_labels[ix1].text = str(get_cell_numer(ix1))
	cage_labels[ix2].text = str(get_cell_numer(ix2))
func classText() -> String:
	if g.qLevel == LVL_BEGINNER: return "【入門】 "
	elif g.qLevel == 1: return "【初級】 "
	elif g.qLevel == 2: return "【初中級】 "
	return ""
func titleText() -> String:
	var tt = classText()
	#elif g.qLevel == LVL_NOT_SYMMETRIC: tt = "【非対称】"
	return tt + "“" + g.qName + "”"

func xyToIX(x, y) -> int: return x + y * N_HORZ
func num_to_bit(n : int): return 1 << (n-1) if n > 0 else 0
func bit_to_num(b):
	var mask = 1
	for i in range(N_HORZ):
		if (b & mask) != 0: return i + 1
		mask <<= 1
	return 0
func bit_to_numstr(b):
	if b == 0: return ""
	return str(bit_to_num(b))
func get_cell_state() -> Array:
	var s = []		#
	for ix in range(N_CELLS):
		if clue_labels[ix].text != "":
			s.push_back(int(clue_labels[ix].text))
		elif input_labels[ix].text != "":
			s.push_back(int(input_labels[ix].text))
		else:
			s.push_back(get_memo_bits(ix) + BIT_MEMO)
	return s
func is_empty_cell(ix) -> bool:
	return input_labels[ix].text == ""
func get_cell_numer(ix) -> int:		# ix 位置に入っている数字の値を返す、0 for 空欄
	#if clue_labels[ix].text != "":
	#	return int(clue_labels[ix].text)
	if input_labels[ix].text != "":
		return int(input_labels[ix].text)
	return 0
func get_memo_bits(ix) -> int:
	var bits = 0
	var mask = BIT_1
	for i in range(N_HORZ):
		if memo_labels[ix][i].text != "": bits |= mask
		mask <<= 1
	return bits
func update_cell_cursor(num):		# 選択数字ボタンと同じ数字セルを強調
	if num > 0 && !paused:
		var num_str = str(num)
		for y in range(N_VERT):
			for x in range(N_HORZ):
				var ix = xyToIX(x, y)
				if num != 0 && get_cell_numer(ix) == num:
					$Board/TileMap.set_cell(0, Vector2i(x, y), TILE_EMPHASIZE, Vector2i(0, 0))
				else:
					$Board/TileMap.set_cell(0, Vector2i(x, y), TILE_NONE)
	else:
		for y in range(N_VERT):
			for x in range(N_HORZ):
				$Board/TileMap.set_cell(0, Vector2i(x, y), TILE_NONE)
				##for v in range(N_BOX_VERT):
				##	for h in range(N_BOX_HORZ):
				##		$Board/MemoTileMap.set_cell(x*3+h, y*3+v), TILE_NONE)
		if cur_cell_ix >= 0:
			do_emphasize_cell(cur_cell_ix)
	pass
func set_num_cursor(num):	# 当該ボタンだけを選択状態に
	cur_num = num
	for i in range(num_buttons.size()):
		num_buttons[i].button_pressed = (i == num)
func update_NEmptyLabel():
	nEmpty = 0
	for ix in range(N_CELLS):
		if get_cell_numer(ix) == 0: nEmpty += 1
	$NEmptyLabel.text = "空欄数: %d" % nEmpty
func update_all_status():
	update_undo_redo()
	update_cell_cursor(cur_num)
	$Board.cur_num = cur_num
	$Board.update()
	update_NEmptyLabel()
	update_num_buttons_disabled()
	check_duplicated()
	check_cages()
	if solvedStat:
		if !g.todaysQuest:
			var six = g.qLevel if g.qNumber == 0 else g.qLevel + 3
			var n = g.stats[six]["NSolved"]
			print("TotalSec = ", g.stats[six]["TotalSec"])
			var avg : int = int(g.stats[six]["TotalSec"] / n)
			var txt = g.sec_to_MSStr(avg)
			var bst = g.sec_to_MSStr(g.stats[six]["BestTime"])
			$MessLabel.text = "グッジョブ！ クリア回数: %d、平均: %s、最短: %s" % [n, txt, bst]
		else:
			$MessLabel.text = "グッジョブ！"
	elif paused:
		$MessLabel.text = "ポーズ中です。解除にはポーズボタンを押してください。"
	elif cur_num > 0:
		$MessLabel.text = "現数字（%d）を入れるセルをクリックしてください。" % cur_num
	elif cur_cell_ix >= 0:
		$MessLabel.text = "セルに入れる数字ボタンをクリックしてください。"
	else:
		$MessLabel.text = "数字ボタンまたは空セルをクリックしてください。"
	##$CoinButton/NCoinLabel.text = str(g.env[g.KEY_N_COINS])
func update_nEmpty():
	nEmpty = 0
	for ix in range(N_CELLS):
		if get_cell_numer(ix) == 0: nEmpty += 1
func is_solved():
	update_nEmpty()
	return nEmpty == 0 && nDuplicated == 0
func init_labels():
	# 手がかり数字、入力数字用 Label 生成
	for y in range(N_VERT):
		for x in range(N_HORZ):
			var px = x * CELL_WIDTH
			var py = y * CELL_WIDTH
			# ケージ合計用ラベル
			var label = Label.new()
			cage_labels.push_back(label)
			label.add_theme_color_override("font_color", Color("#2980b9"))	# VELIZE HOLE
			label.add_theme_font_size_override("font_size", 28)
			label.position = Vector2(px + 6, py + 0)
			label.text = str((x+y)%11 + 1)
			$Board.add_child(label)
			# 入力数字用ラベル
			label = Label.new()
			input_labels.push_back(label)
			label.add_theme_color_override("font_color", Color.BLACK)
			label.add_theme_font_size_override("font_size", 60)
			label.position = Vector2(px+32, py + 4)
			label.text = str((x+y)%6 + 1)
			$Board.add_child(label)
			# 候補数字用ラベル
			var lst = []
			for v in range(N_BOX_VERT):
				for h in range(N_BOX_HORZ):
					label = Label.new()
					lst.push_back(label)
					label.add_theme_color_override("font_color", Color.BLACK)
					label.add_theme_font_size_override("font_size", 18)
					label.position = g.memo_label_pos(px, py, h, v)
					label.text = ""
					#label.text = str(v*3+h+1)
					$Board.add_child(label)
			memo_labels.push_back(lst)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !solvedStat && !paused:
		g.elapsedTime += delta
		var sec = int(g.elapsedTime)
		var h = sec / (60*60)
		sec -= h * (60*60)
		var m = sec / 60
		sec -= m * 60
		$TimeLabel.text = "%02d:%02d:%02d" % [h, m, sec]
	##if confetti_count_down > 0.0:
	##	confetti_count_down -= delta
	##	if confetti_count_down <= 0.0:
	##		$FakeConfettiParticles.emitting = false
	##if hint_count_down > 0.0:
	##	hint_count_down -= delta
	##	if hint_count_down <= 0.0:
	##		#var num = bit_to_num(ans_bit[hint_ix])
	##		var num = ans_num[hint_ix]
	##		var lst = remove_memo_num(hint_ix, num)
	##		var mb = get_memo_bits(hint_ix)
	##		remove_all_memo_at(hint_ix)
	##		push_to_undo_stack([UNDO_TYPE_CELL, hint_ix, 0, num, lst, mb])
	##		input_labels[hint_ix].text = str(num)
	##		if is_solved():
	##			on_solved()
	##		update_all_status()
	##		input_num = num
	##		sound_effect(false)		# ヒント数字確定
	##	else:
	##		var num = rng.randi_range(1, N_HORZ)
	##		input_labels[hint_ix].text = str(num)
	if shock_wave_timer >= 0:
		shock_wave_timer += delta
		$CanvasLayer/ColorRect.material.set("shader_param/size", shock_wave_timer)
		if shock_wave_timer > 2:
			shock_wave_timer = -1.0
	pass
func gen_ans_sub(ix : int, line_used):
	#print_cells()
	#print_box_used()
	var x : int = ix % N_HORZ
	if x == 0: line_used = 0
	var x3 = x / 3
	var y2 = ix / (N_HORZ*2)
	var bix = y2 * 2 + x3
	var used = line_used | column_used[x] | box_used[bix]
	if used == ALL_BITS: return false		# 全数字が使用済み
	var lst = []
	var mask = BIT_1
	for i in range(N_HORZ):
		if (used & mask) == 0: lst.push_back(mask)		# 数字未使用の場合
		mask <<= 1
	if ix == N_CELLS - 1:
		cell_bit[ix] = lst[0]
		return true
	if lst.size() > 1: lst.shuffle()
	for i in range(lst.size()):
		cell_bit[ix] = lst[i]
		column_used[x] |= lst[i]
		box_used[bix] |= lst[i]
		if gen_ans_sub(ix+1, line_used | lst[i]): return true
		column_used[x] &= ~lst[i]
		box_used[bix] &= ~lst[i]
	cell_bit[ix] = 0
	return false;
func gen_ans():		# 解答生成
	print("gen_ans():")
	for i in range(N_CELLS):
		#clue_labels[i].text = "?"
		input_labels[i].text = ""
	for i in range(box_used.size()): box_used[i] = 0
	for i in range(cell_bit.size()): cell_bit[i] = 0
	var t = []
	for i in range(N_HORZ): t.push_back(1<<i)
	t.shuffle()
	for i in range(N_HORZ):
		cell_bit[i] = t[i]
		column_used[i] = t[i]
		box_used[i/3] |= t[i]
	#print(cell_bit)
	gen_ans_sub(N_HORZ, 0)
	#print_cells()
	#update_cell_labels()
	#ans_bit = cell_bit.duplicate()
	#for i in range(N_CELLS): ans_bit[i] = cell_bit[i]
	for i in range(N_CELLS): ans_num[i] = bit_to_num(cell_bit[i])
	#print_ans()
	#print_ans_num()
	for i in range(N_CELLS): input_labels[i].text = ""		# 入力ラベル全消去
	#for i in range(N_CELLS): input_labels[i].text = bit_to_numstr(cell_bit[i])
	print_cells()
	pass
func print_cells():
	var ix = 0
	for y in range(N_VERT):
		var lst = []
		for x in range(N_HORZ):
			var n = bit_to_num(cell_bit[ix])
			#input_labels[ix].text = str(n)
			lst.push_back(n)
			ix += 1
		print(lst)
	print("")
func print_ans_num():
	print("ans_num:")
	var ix = 0
	for y in range(N_VERT):
		var lst = []
		for x in range(N_HORZ):
			lst.push_back(ans_num[ix])
			ix += 1
		print(lst)
	print("")
func print_cages():
	for i in range(cage_list.size()):
		print(cage_list[i])
func merge_2cell_cage():	# 2セルケージ２つをマージし4セルに
	#print_cages()
	while true:
		var ix = rng.randi_range(0, N_CELLS-1)
		var cix = cage_ix[ix]
		if cage_list[cix][CAGE_IX_LIST].size() != 2: continue
		var lst2 = []
		var x = ix % N_HORZ
		var y = ix / N_HORZ
		if y != 0:
			var i2 = xyToIX(x, y-1)
			if cage_ix[i2] != cix && cage_list[cage_ix[i2]][CAGE_IX_LIST].size() == 2:
				lst2.push_back(i2)
		if x != 0:
			var i2 = xyToIX(x-1, y)
			if cage_ix[i2] != cix && cage_list[cage_ix[i2]][CAGE_IX_LIST].size() == 2:
				lst2.push_back(i2)
		if x != N_HORZ-1:
			var i2 = xyToIX(x+1, y)
			if cage_ix[i2] != cix && cage_list[cage_ix[i2]][CAGE_IX_LIST].size() == 2:
				lst2.push_back(i2)
		if y != N_VERT-1:
			var i2 = xyToIX(x, y+1)
			if cage_ix[i2] != cix && cage_list[cage_ix[i2]][CAGE_IX_LIST].size() == 2:
				lst2.push_back(i2)
		if lst2.is_empty(): continue
		var ix2 = lst2[0] if lst2.size() == 1 else lst2[rng.randi_range(0, lst2.size() - 1)]
		var cix2 = cage_ix[ix2]
		#print("cix = ", cage_list[cix])
		#print("cix2 = ", cage_list[cix2])
		for i in range(cage_list[cix2][CAGE_IX_LIST].size()):
			cage_ix[cage_list[cix2][CAGE_IX_LIST][i]] = cix
		cage_list[cix][CAGE_IX_LIST] += cage_list[cix2][CAGE_IX_LIST]
		cage_list[cix][CAGE_SUM] += cage_list[cix2][CAGE_SUM]
		cage_list[cix2] = [0, []]
		#print_cages()
		return
func gen_cages_3x2():
	for i in range(N_CELLS): cage_labels[i].text = ""
	cage_list = []
	for y in range(0, N_VERT, N_VERT/3):
		for x in range(0, N_HORZ, N_HORZ/2):
			var ix = xyToIX(x, y)
			if rng.randf_range(0.0, 1.0) < 0.5:
				# 縦＋横*2行
				cage_list.push_back([0, [ix, ix+N_HORZ]])
				cage_list.push_back([0, [ix+1, ix+2]])
				cage_list.push_back([0, [ix+N_HORZ+1, ix+N_HORZ+2]])
			else:
				# 横*2行＋縦
				cage_list.push_back([0, [ix, ix+1]])
				cage_list.push_back([0, [ix+N_HORZ, ix+N_HORZ+1]])
				cage_list.push_back([0, [ix+2, ix+N_HORZ+2]])
	for i in range(cage_ix.size()): cage_ix[i] = -1
	for ix in range(cage_list.size()):
		var lst = cage_list[ix][1]
		for k in range(lst.size()): cage_ix[lst[k]] = ix
	$Board/CageGrid.cage_ix = cage_ix
	$Board/CageGrid.update()
func sel_from_lst(ix, lst):		# lst からひとつを選ぶ
	if g.qLevel != LVL_NORMAL:
		return lst[rng.randi_range(0, lst.size() - 1)]
	var n = get_cell_numer(ix)
	if n <= 3:		# 3以下の場合は、最大のものを選ぶ
		var mx = 0
		var mxi = 0
		for i in range(lst.size()):
			var n2 = get_cell_numer(lst[i])
			if n2 > mx:
				mx = n2
				mxi = i
		return lst[mxi]
	else:		# 4以上の場合は、最小のものを選ぶ
		var mn = N_HORZ + 1
		var mni = 0
		for i in range(lst.size()):
			var n2 = get_cell_numer(lst[i])
			if n2 < mn:
				mn = n2
				mni = i
		return lst[mni]
func gen_cages():
	for i in range(N_CELLS): cage_labels[i].text = ""
	cage_list = []
	# 4隅を風車風に２セルケージに分ける
	if rng.randf_range(0.0, 1.0) < 0.5:
		cage_list.push_back([0, [0, 1]])
		var ix0 = N_HORZ-1
		cage_list.push_back([0, [ix0, ix0+N_HORZ]])
		ix0 = N_HORZ * (N_VERT - 1)
		cage_list.push_back([0, [ix0, ix0-N_HORZ]])
		ix0 = N_CELLS - 1
		cage_list.push_back([0, [ix0, ix0-1]])
	else:
		cage_list.push_back([0, [0, N_HORZ]])
		var ix0 = N_HORZ-1
		cage_list.push_back([0, [ix0, ix0-1]])
		ix0 = N_HORZ * (N_VERT - 1)
		cage_list.push_back([0, [ix0, ix0+1]])
		ix0 = N_CELLS - 1
		cage_list.push_back([0, [ix0, ix0-N_HORZ]])
	for i in range(cage_ix.size()): cage_ix[i] = -1
	for ix in range(cage_list.size()):
		var lst = cage_list[ix][1]
		for k in range(lst.size()): cage_ix[lst[k]] = ix
	# undone: 入門問題の場合は１セルケージを8つ、初級の場合は２つ生成
	if g.qLevel < LVL_NORMAL:
		var cnt = 4 if g.qLevel == LVL_BEGINNER else 2
		while cnt > 0:
			var ix = rng.randi_range(0, N_CELLS-1)
			if cage_ix[ix] >= 0: continue
			cage_ix[ix] = cage_list.size()
			cage_list.push_back([0, [ix]])
			cnt -= 1
	#
	var ar = []
	for ix in range(N_CELLS): ar.push_back(ix)
	ar.shuffle()
	for i in range(ar.size()):
		var ix = ar[i]
		if cage_ix[ix] < 0:	# 未分割の場合
			if false:
			#if g.qLevel == LVL_BEGINNER && i >= ar.size() - N_HORZ*2.2:
			#if g.qLevel == LVL_BEGINNER && rng.randf_range(0.0, 1.0) < 0.1:
				cage_ix[ix] = cage_list.size()
				cage_list.push_back([0, [ix]])
			else:
				var x = ix % N_HORZ
				var y = ix / N_HORZ
				var lst0 = []	# 空欄リスト
				var lst1 = []	# １セルケージリスト
				var lst2 = []	# ２セルケージリスト
				if y != 0:
					var i2 = xyToIX(x, y-1)
					if cage_ix[i2] < 0: lst0.push_back(i2)	# 空欄の場合
					elif cage_list[cage_ix[i2]][CAGE_IX_LIST].size() == 1: lst1.push_back(i2)
					elif cage_list[cage_ix[i2]][CAGE_IX_LIST].size() == 2: lst2.push_back(i2)
				if x != 0:
					var i2 = xyToIX(x-1, y)
					if cage_ix[i2] < 0: lst0.push_back(i2)	# 空欄の場合
					elif cage_list[cage_ix[i2]][CAGE_IX_LIST].size() == 1: lst1.push_back(i2)
					elif cage_list[cage_ix[i2]][CAGE_IX_LIST].size() == 2: lst2.push_back(i2)
				if x != N_HORZ-1:
					var i2 = xyToIX(x+1, y)
					if cage_ix[i2] < 0: lst0.push_back(i2)	# 空欄の場合
					elif cage_list[cage_ix[i2]][CAGE_IX_LIST].size() == 1: lst1.push_back(i2)
					elif cage_list[cage_ix[i2]][CAGE_IX_LIST].size() == 2: lst2.push_back(i2)
				if y != N_VERT-1:
					var i2 = xyToIX(x, y+1)
					if cage_ix[i2] < 0: lst0.push_back(i2)	# 空欄の場合
					elif cage_list[cage_ix[i2]][CAGE_IX_LIST].size() == 1: lst1.push_back(i2)
					elif cage_list[cage_ix[i2]][CAGE_IX_LIST].size() == 2: lst2.push_back(i2)
				#if ix == 13 || ix == 14:
				#	print("ix = ", ix)
				if !lst0.is_empty():	# ４近傍に未分割セルがある場合
					#var ix2 = lst0[0] if lst0.size() == 1 else lst0[rng.randi_range(0, lst0.size() - 1)]
					var ix2 = lst0[0] if lst0.size() == 1 else sel_from_lst(ix, lst0)
					#cage_list.back()[1].push_back(i2)
					cage_ix[ix] = cage_list.size()
					cage_ix[ix2] = cage_list.size()
					cage_list.push_back([0, [ix, ix2]])
				#if !lst1.is_empty():	# ４近傍に1セルケージがある場合
				#	# 1セルのケージに ix をマージ
				#	var i2 = lst1[0] if lst1.size() == 1 else lst1[rng.randi_range(0, lst1.size() - 1)]
				#	var lstx = cage_ix[i2]
				#	cage_list[lstx][CAGE_IX_LIST].push_back(ix)
				#	cage_ix[ix] = lstx
				elif !lst2.is_empty() && g.qLevel != LVL_BEGINNER:	# ４近傍に２セルのケージがある場合
					# ２セルのケージに ix をマージ
					var i2 = lst2[0] if lst2.size() == 1 else lst2[rng.randi_range(0, lst2.size() - 1)]
					var lstx = cage_ix[i2]
					cage_list[lstx][1].push_back(ix)
					cage_ix[ix] = lstx
				else:
					cage_ix[ix] = cage_list.size()
					cage_list.push_back([0, [ix]])
	for ix in range(cage_list.size()):		# 各ケージの合計を計算
		var item = cage_list[ix]
		var sum = 0
		var lst = item[CAGE_IX_LIST]
		for k in range(lst.size()):
			sum += bit_to_num(cell_bit[lst[k]])
		item[CAGE_SUM] = sum
		print(cage_list[ix])
		if sum != 0:
			cage_labels[lst.min()].text = str(sum)
		#for k in range(lst.size()): cage_ix[lst[k]] = ix
	quest_cages = cage_list
	$Board/CageGrid.cage_ix = cage_ix
	$Board/CageGrid.update()
func update_cages_sum_labels():
	for ix in range(cage_labels.size()):
		cage_labels[ix].text = ""
	for ix in range(cage_list.size()):
		var item = cage_list[ix]
		var sum = item[CAGE_SUM]
		var lst = item[CAGE_IX_LIST]
		if sum != 0:
			cage_labels[lst.min()].text = str(sum)
func ipq_sub(cix, lix, ub, sum) -> bool:	# false for 解の個数が２以上
	if cix == cage_list.size():
		nAnswer += 1
		print(nAnswer, ":")
		print_cells()	# cell_bit の内容を表示
		for i in range(N_CELLS):
			ans_num[i] = bit_to_num(cell_bit[i])
			#ans_bit[i] = cell_bit[i]
		#print_ans()
		print_ans_num()
	else:
		var cage = cage_list[cix]
		if cage[CAGE_SUM] == 0:
			ipq_sub(cix+1, 0, 0, 0)
			return nAnswer < 2
		#if cage[CAGE_IX_LIST].size() == 1:
		#	print("cage[CAGE_IX_LIST].size() == 1")
		var ix = cage[CAGE_IX_LIST][lix]
		assert( ix >= 0 && ix < N_CELLS )
		var x = ix % N_HORZ
		var y = ix / N_HORZ
		var x3 = x / 3
		var y2 = y / 2
		var bix = y2 * 2 + x3
		var bits = ~(ub | line_used[y] | column_used[x] | box_used[bix]) & ALL_BITS
		if !bits: return true		# 配置可能ビット無し
		if lix == cage[CAGE_IX_LIST].size() - 1:		# 最後のセルの場合
			var n = cage[CAGE_SUM] - sum
			var b = num_to_bit(n)
			if n <= 0 || (bits&b) == 0:
				return true
			line_used[y] |= b
			column_used[x] |= b
			box_used[bix] |= b
			cell_bit[ix] = b
			if !ipq_sub(cix+1, 0, 0, 0):
				return false
			line_used[y] ^= b
			column_used[x] ^= b
			box_used[bix] ^= b
		else:	# 最後のセルでない場合
			while bits != 0:
				var b = -bits & bits		# 最も小さい１のビット
				bits ^= b					# b のビットを消去
				line_used[y] |= b
				column_used[x] |= b
				box_used[bix] |= b
				cell_bit[ix] = b
				if !ipq_sub(cix, lix+1, (ub | b), sum+bit_to_num(b)):
					return false
				line_used[y] ^= b
				column_used[x] ^= b
				box_used[bix] ^= b
		#assert( ix >= 0 && ix < N_CELLS )
		cell_bit[ix] = 0
	return nAnswer < 2
# cage_list をチェック、手がかり数字は無し
func is_proper_quest() -> bool:
	nAnswer = 0
	for ix in range(N_CELLS): cell_bit[ix] = 0
	for ix in range(N_HORZ):
		line_used[ix] = 0
		column_used[ix] = 0
		box_used[ix] = 0
	ipq_sub(0, 0, 0, 0)
	return nAnswer == 1
func set_quest(cages):
	quest_cages = cages
	##for y in range(N_VERT):
	##	for x in range(N_HORZ):
	##		$Board/CageTileMap.set_cell(0, Vector2i(x, y), -1)
	#var col = 0
	for cix in range(cages.size()):
		var item = cages[cix]			# [sum, col, ix1, ix2, ... ]
		cage_labels[item[1]].text = str(item[0])
		var x1 = item[1] % N_HORZ
		var y1 = item[1] / N_HORZ
		#while( $Board/CageTileMap.get_cell(x1, y1-1) == col || $Board/CageTileMap.get_cell(x1-1, y1) == col ||
		#		$Board/CageTileMap.get_cell(x1, y1+1) == col || $Board/CageTileMap.get_cell(x1+1, y1) == col ):
		#	col = (col + 1) % N_COLOR
		#var col = item[1]
		for k in range(1, item.size()):
			cage_ix[item[k]] = cix
			#var x = item[k] % N_HORZ
			#var y = item[k] / N_HORZ
			#$Board/CageTileMap.set_cell(0, Vector2i(x, y), col)
	$Board/CageGrid.cage_ix = cage_ix
	$Board/CageGrid.update()
	#update()
func is_duplicated(ix : int):
	var n = get_cell_numer(ix)
	if n == 0: return false
	var x = ix % N_HORZ
	var y = ix / N_HORZ
	for t in range(N_HORZ):
		if t != x && get_cell_numer(xyToIX(t, y)) == n:
			return true
		if t != y && get_cell_numer(xyToIX(x, t)) == n:
			return true
	var x0 = x - x % 3		# 3x2ブロック左上位置
	var y0 = y - y % 2
	for v in range(N_BOX_VERT):
		for h in range(N_BOX_HORZ):
			var ix3 = xyToIX(x0+h, y0+v)
			if ix3 != ix && get_cell_numer(ix3) == n:
				return true
	# ケージ内の重複チェック
	var cage = cage_list[cage_ix[ix]]
	if cage[CAGE_IX_LIST].size() != 1:
		#var bit = cell_bit[ix]
		var lst = cage[CAGE_IX_LIST]
		for i in range(lst.size()):
			if lst[i] != ix && get_cell_numer(lst[i]) == n:
				return true
	return false
func check_duplicated():
	nDuplicated = 0
	for ix in range(N_CELLS):
		if is_duplicated(ix):
			nDuplicated += 1
			#clue_labels[ix].add_theme_color_override("font_color", COLOR_DUP)
			input_labels[ix].add_theme_color_override("font_color", COLOR_DUP)
		else:
			#clue_labels[ix].add_theme_color_override("font_color", COLOR_CLUE)
			input_labels[ix].add_theme_color_override("font_color", COLOR_INPUT)
	pass
func check_cages():		# 必ず check_duplicated() の直後にコールすること
	for i in range(cage_list.size()):
		var ixs = cage_list[i][1]
		var sum = 0
		for k in range(ixs.size()):
			var n = get_cell_numer(ixs[k])
			if n == 0:
				sum = 0
				break
			sum += n
		if sum != 0 && sum != cage_list[i][0]:
			nDuplicated += 1
			for k in range(ixs.size()):
				input_labels[ixs[k]].add_theme_color_override("font_color", COLOR_DUP)
	pass
func update_num_buttons_disabled():		# 使い切った数字ボタンをディセーブル
	#var nUsed = []		# 各数字の使用数 [0] for EMPTY
	if paused:
		for i in range(N_HORZ+1):
			num_buttons[i].disabled = true
	else:
		for i in range(N_HORZ+1): num_used[i] = 0
		for ix in range(N_CELLS):
			num_used[get_cell_numer(ix)] += 1
		for i in range(N_HORZ):
			num_buttons[i+1].disabled = num_used[i+1] >= N_HORZ
func update_undo_redo():
	$HBC1/UndoButton.disabled = undo_ix == 0
	$HBC1/RedoButton.disabled = undo_ix == undo_stack.size()
func push_to_undo_stack(item):
	if undo_stack.size() > undo_ix:
		undo_stack.resize(undo_ix)
	undo_stack.push_back(item)
	undo_ix += 1
func sound_effect(selected):
	if sound:
		if nDuplicated != 0:
			$Audio/Incorrect.play()
		elif input_num > 0 && num_used[input_num] >= N_HORZ:
			$Audio/NumCompleted.play()
		else:
			$Audio/NumClicked.play()		# pon
func clear_cell_cursor():
	for y in range(N_VERT):
		for x in range(N_HORZ):
			$Board/TileMap.set_cell(0, Vector2i(x, y), TILE_NONE)
func reset_TileMap():
	for y in range(N_VERT):
		for x in range(N_HORZ):
			$Board/TileMap.set_cell(0, Vector2i(x, y), TILE_NONE)
func do_emphasize_cell(ix : int):
	if paused: return
	reset_TileMap()
	var n = get_cell_numer(ix)
	if n != 0:
		update_cell_cursor(n)
	var x = ix % N_HORZ
	var y = ix / N_HORZ
	$Board/TileMap.set_cell(0, Vector2i(x, y), TILE_CURSOR, Vector2i(0, 0))
func do_emphasize(ix : int, type, fullhouse):
	reset_TileMap()
	if paused: return
	var x = ix % N_HORZ
	var y = ix / N_HORZ
	if type == CELL || fullhouse:
		$Board/TileMap.set_cell(0, Vector2i(x, y), TILE_CURSOR, Vector2i(0, 0))
	pass

func is_all_solved_todaysQuest():
	return g.tqSolvedSec[0] >= 0 && g.tqSolvedSec[1] >= 0 && g.tqSolvedSec[2] >= 0
func on_solved():
	solvedStat = true
	confetti_count_down = 5.0
	$CPUParticles2D.emitting = true
	$CanvasLayer/ColorRect.show()
	shock_wave_timer = 0.0      # start shock wave
	if sound:
		$Audio/Solved.play()		# （キラーン）効果音再生
	var six = g.qLevel		# g.stat インデックス
	if g.todaysQuest:		# 今日の問題の場合
		if g.tqSolvedSec[six] < 0 || int(g.elapsedTime) < g.tqSolvedSec[six]:
			g.tqSolvedSec[six] = int(g.elapsedTime)	# 最短クリア時間更新
		if is_all_solved_todaysQuest() && g.tqConsSolvedDays != g.tqConsYesterdayDays + 1:
			# 全問クリアの場合
			g.tqConsSolvedDays = g.tqConsYesterdayDays + 1
			if g.tqConsSolvedDays > g.tqMaxConsSolvedDays:
				g.tqMaxConsSolvedDays = g.tqConsSolvedDays		# 最大連続クリア日数
			g.env[g.KEY_N_COINS] += g.TODAYS_QUEST_N_COINS
			$CoinButton/NCoinLabel.text = str(g.env[g.KEY_N_COINS])
			g.save_environment()
		g.tqSolvedYMD = g.today_string()
		g.save_todaysQuest()
	else:	# 今日の問題でない場合
		if g.qNumber != 0:		# 問題集の場合
			if g.nSolved[g.qLevel] == g.qNumber - 1:	
				g.nSolved[g.qLevel] += 1
				g.save_nSolved()
				$NextButton.disabled = false
			six += 3		# for 統計情報
		if g.stats[six].has("NSolved"):
			g.stats[six]["NSolved"] += 1
		else:
			g.stats[six]["NSolved"] = 1
		if g.stats[six].has("TotalSec"):
			print("TotalSec = ", g.stats[six]["TotalSec"])
			g.stats[six]["TotalSec"] += int(g.elapsedTime)
		else:
			g.stats[six]["TotalSec"] = int(g.elapsedTime)
		if !g.stats[six].has("BestTime") || g.stats[six]["BestTime"] < 1 || int(g.elapsedTime) < g.stats[six]["BestTime"]:
			g.stats[six]["BestTime"] = int(g.elapsedTime)
		g.save_stats()
	cur_cell_ix = -1		# 選択解除
	cur_num = -1
	update_all_status()
func remove_all_memo_at(ix):
	for i in range(N_HORZ):
		if memo_labels[ix][i].text != "":
			add_falling_memo(int(memo_labels[ix][i].text), ix)
			memo_labels[ix][i].text = ""
func remove_all_memo():
	for ix in range(N_CELLS):
		for i in range(N_HORZ):
			if memo_labels[ix][i].text != "":
				add_falling_memo(int(memo_labels[ix][i].text), ix)
				memo_labels[ix][i].text = ""
	for v in range(N_VERT*3):
		for h in range(N_HORZ*3):
			$Board/MemoTileMap.set_cell(0, Vector2i(h, v), TILE_NONE)
func remove_memo_num(ix : int, num : int):		# ix に num を入れたときに、メモ数字削除
	var lst = []
	var x = ix % N_HORZ
	var y = ix / N_HORZ
	for h in range(N_HORZ):
		var ix2 = xyToIX(h, y)
		if memo_labels[ix2][num-1].text != "":
			add_falling_memo(num, ix2)
			memo_labels[ix2][num-1].text = ""
			lst.push_back(ix2)
		ix2 = xyToIX(x, h)
		if memo_labels[ix2][num-1].text != "":
			add_falling_memo(num, ix2)
			memo_labels[ix2][num-1].text = ""
			lst.push_back(ix2)
	var x0 = x - x % 3
	var y0 = y - y % 2
	for v in range(N_BOX_VERT):
		for h in range(N_BOX_HORZ):
			var ix2 = xyToIX(x0 + h, y0 + v)
			if memo_labels[ix2][num-1].text != "":
				add_falling_memo(num, ix2)
				memo_labels[ix2][num-1].text = ""
				lst.push_back(ix2)
	return lst
func flip_memo_num(ix : int, num : int):
	if memo_labels[ix][num-1].text == "":
		memo_labels[ix][num-1].text = str(num)
	else:
		add_falling_memo(int(memo_labels[ix][num-1].text), ix)
		memo_labels[ix][num-1].text = ""
func flip_memo_bits(ix, bits):
	var mask = BIT_1
	for n in range(N_HORZ):
		if (bits & mask) != 0:
			flip_memo_num(ix, n+1)
		mask <<= 1
func set_memo_bits(ix, bits):
	var mask = BIT_1
	for i in range(N_HORZ):
		if (bits & mask) != 0:
			memo_labels[ix][i].text = str(i+1)
		else:
			memo_labels[ix][i].text = ""
		mask <<= 1
func clear_all_memo(ix):
	for i in range(N_HORZ): memo_labels[ix][i].text = ""
func _input(event):
	#print("_input()")
	if menuPopuped: return
	if event is InputEventMouseButton && event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP || event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				return
		print("event.is_pressed()")
		var mp = $Board/TileMap.local_to_map($Board/TileMap.get_local_mouse_position())
		print(mp)
		if mp.x < 0 || mp.x >= N_HORZ || mp.y < 0 || mp.y >= N_VERT:
			return		# 盤面セル以外の場合
		input_num = -1
		var ix = xyToIX(mp.x, mp.y)
		if false: #clue_labels[ix].text != "":
			# undone: 手がかり数字ボタン選択
			#num_button_pressed(int(clue_labels[ix].text), true)
			pass
		else:
			if cur_num < 0:			# 数字ボタン非選択の場合
				clear_cell_cursor()
				if ix == cur_cell_ix:
					cur_cell_ix = -1
				else:
					cur_cell_ix = ix
					do_emphasize_cell(ix)
				update_all_status()
				#sound_effect(true)
				return
			if cur_num == 0:	# 削除ボタン選択中
				if input_labels[ix].text != "":
					add_falling_char(input_labels[ix].text, ix)
					push_to_undo_stack([UNDO_TYPE_CELL, ix, int(input_labels[ix].text), 0, [], 0])		# ix, old, new
					input_labels[ix].text = ""
					cell_bit[ix] = 0
				else:
					for i in range(N_HORZ):
						if memo_labels[ix][i].text != "":
					#		add_falling_memo(int(memo_labels[ix][i].text), ix)
							memo_labels[ix][i].text = ""	# メモ数字削除
					pass
			# 数字ボタン選択状態の場合 → セルにその数字を入れる or メモ数字反転
			elif !memo_mode:
				if input_labels[ix].text != "":
					add_falling_char(input_labels[ix].text, ix)
				var num_str = str(cur_num)
				if input_labels[ix].text == num_str:	# 同じ数字が入っていれば消去
					push_to_undo_stack([UNDO_TYPE_CELL, ix, int(cur_num), 0, [], 0])		# ix, old, new
					input_labels[ix].text = ""
					cell_bit[ix] = 0
				else:	# 上書き
					input_num = int(cur_num)
					var lst = remove_memo_num(ix, cur_num)
					var mb = get_memo_bits(ix)
					push_to_undo_stack([UNDO_TYPE_CELL, ix, int(input_labels[ix].text), input_num, lst, mb])
					input_labels[ix].text = num_str
					cell_bit[ix] = num_to_bit(cur_num)
				for i in range(N_HORZ): memo_labels[ix][i].text = ""	# メモ数字削除
			else:	# 候補数字モード
				if get_cell_numer(ix) != 0:
					return		# 空欄でない場合
				push_to_undo_stack([UNDO_TYPE_MEMO, ix, cur_num])
				flip_memo_num(ix, cur_num)
		update_all_status()
		sound_effect(false)
		if !solvedStat && is_solved():
			on_solved()
	elif event is InputEventKey && event.is_pressed():
		#print(event.as_text())
		if paused: return
		if event.as_text() == "H" :
			_on_hint_button_pressed()
			return
		elif event.as_text() == "W" :
			shock_wave_timer = 0.0      # start shock wave
		var n = int(event.as_text())
		if n >= 1 && n <= N_HORZ:
			num_button_pressed(n, true)
	pass
#func _unhandled_input(event):
#	print("_unhandled_input()")
#	pass
func add_falling_char(num_str, ix : int):
	var fc = FallingChar.instantiate()
	var x = ix % N_HORZ
	var y = ix / N_HORZ
	fc.position = $Board.position + Vector2(x*CELL_WIDTH, y*CELL_WIDTH)
	fc.get_node("Label").text = num_str
	var th = rng.randf_range(0, 3.1415926535*2)
	fc.linear_velocity = Vector2(cos(th), sin(th))*100
	fc.angular_velocity = rng.randf_range(0, 1)
	add_child(fc)
	pass
func add_falling_memo(num : int, ix : int):
	var fc = Label.new()
	#var x = (ix % N_HORZ) * 3 + (num-1) % 3
	#var y = (ix / N_HORZ) * 3 + (num-1) / 3
	#fc.position = $Board.rect_position + Vector2(x*CELL_WIDTH/3, y*CELL_WIDTH/3)
	var px = (ix % N_HORZ) * CELL_WIDTH
	var py = (ix / N_HORZ) * CELL_WIDTH
	var h = (num-1) % 3
	var v = (num-1) / 3
	fc.position = $Board.rect_position + g.memo_label_pos(px, py, h, v)
	fc.text = str(num)
	var th = rng.randf_range(0, 3.1415926535*2)
	fc.linear_velocity = Vector2(cos(th), sin(th))*100
	fc.angular_velocity = rng.randf_range(0, 1)
	#fc.set_scale(1.0/3.0)
	add_child(fc)
	pass
func add_falling_coin():
	var fc = Label.new()	# ほんとは TextureRect
	fc.position = $CoinButton.rect_position + $CoinButton.rect_size / 2
	var th = rng.randf_range(0, 3.1415926535*2)
	fc.linear_velocity = Vector2(cos(th), sin(th))*100
	fc.angular_velocity = rng.randf_range(0, 1)
	add_child(fc)
func num_button_pressed(num : int, button_pressed):
	#print("num = ", num)
	if in_button_pressed: return		# ボタン押下処理中の場合
	if paused: return			# ポーズ中
	in_button_pressed = true
	if cur_cell_ix >= 0:		# セルが選択されている場合
		if num == 0:			# 削除ボタン押下の場合
			var old = get_cell_numer(cur_cell_ix)
			if old != 0:
				add_falling_char(input_labels[cur_cell_ix].text, cur_cell_ix)
				push_to_undo_stack([UNDO_TYPE_CELL, cur_cell_ix, old, 0, [], 0])
				input_labels[cur_cell_ix].text = ""
				cell_bit[cur_cell_ix] = 0
			##else:
			##	remove_all_memo_at(cur_cell_ix)
		else:		# 数字ボタン押下の場合
			if !memo_mode:
				if button_pressed:
					var old = get_cell_numer(cur_cell_ix)
					if old != 0:
						add_falling_char(input_labels[cur_cell_ix].text, cur_cell_ix)
					if num == old:		# 同じ数字を入れる → 削除
						push_to_undo_stack([UNDO_TYPE_CELL, cur_cell_ix, old, 0, [], 0])
						input_labels[cur_cell_ix].text = ""
						cell_bit[cur_cell_ix] = 0
					else:
						input_num = num
						var lst = remove_memo_num(cur_cell_ix, num)
						var mb = get_memo_bits(cur_cell_ix)
						push_to_undo_stack([UNDO_TYPE_CELL, cur_cell_ix, old, num, lst, mb])
						#undo_stack.back().back() = lst
						input_labels[cur_cell_ix].text = str(num)
						cell_bit[cur_cell_ix] = num_to_bit(num)
					for i in range(N_HORZ):
						if memo_labels[cur_cell_ix][i].text != "":
							add_falling_memo(int(memo_labels[cur_cell_ix][i].text), cur_cell_ix)
							memo_labels[cur_cell_ix][i].text = ""
					num_buttons[num].button_pressed = false
					update_all_status()
					sound_effect(false)
					if !solvedStat && is_solved():
						on_solved()
				pass
			else:		# メモ数字エディットモード
				if get_cell_numer(cur_cell_ix) == 0:	# 数字が入っていない場合
					push_to_undo_stack([UNDO_TYPE_MEMO, cur_cell_ix, num])
					flip_memo_num(cur_cell_ix, num)
				set_num_cursor(-1)
		pass
	else:	# セルが選択されていない場合
		if button_pressed:
			set_num_cursor(num)
		else:
			cur_num = -1		# toggled
		update_cell_cursor(cur_num)
		#sound_effect(true)
	in_button_pressed = false
	update_all_status()
	pass

func _on_button_1_pressed():
	num_button_pressed(1, true)
func _on_button_2_pressed():
	num_button_pressed(2, true)
	pass # Replace with function body.
func _on_button_3_pressed():
	num_button_pressed(3, true)
	pass # Replace with function body.
func _on_button_4_pressed():
	pass # Replace with function body.
	num_button_pressed(4, true)
func _on_button_5_pressed():
	num_button_pressed(5, true)
	pass # Replace with function body.
func _on_button_6_pressed():
	num_button_pressed(6, true)
	pass # Replace with function body.
func find_last_blank_cell_in_cage():		# ケージ内の最後の空白セルを探す
	for ci in range(cage_list.size()):
		var cage = cage_list[ci]
		var sum = cage[CAGE_SUM]
		var lst = cage[CAGE_IX_LIST]
		var nspc = lst.size()		# 当該ケージ内の空白セル数
		var bix					# 空欄セル位置
		for i in range(lst.size()):
			var cn = get_cell_numer(lst[i])
			if get_cell_numer(lst[i]) != 0:
				nspc -= 1
				sum -= cn
			else:
				bix = lst[i]
		if nspc == 1:
			return [bix, sum]
	return [-1, -1]
# (x0, y0)-(x0+wd, y0+ht) 範囲にルール21を適用できるかどうかチェック
# return: [数字が決まる位置, 入る数字]
func check_rule21(x0:int, y0:int, wd:int, ht:int):
	var cage_processed = []				# ケージ処理済みフラグ
	cage_processed.resize(cage_list.size())
	cage_processed.fill(false)
	var cage_sum_in = []				# 各ケージのエリア内数字合計
	cage_sum_in.resize(cage_list.size())
	cage_sum_in.fill(0)
	#var cage_sum_out = cage_sum_in.duplicate()	# 各ケージのエリア外数字合計
	#var not_empty_cage = []				# ケージが非空欄セルを含むか？
	#not_empty_cage.resize(cage_list.size())
	#not_empty_cage.fill(false)
	var cxio = -1		# ケージ内セルのエリア内外数が1のケージIX
	var ix0				# 確定する箇所
	var nis				# ケージ内セルのエリア内数
	for v in range(ht):
		for h in range(wd):
			var cx = cage_ix[xyToIX(x0+h, y0+v)]
			if !cage_processed[cx]:		# ケージが未処理の場合
				cage_processed[cx] = true	# 処理済みフラグON
				var cage = cage_list[cx]
				var ni = 0		# 当該ケージのエリア内セル数
				var no = 0		# 当該ケージのエリア外セル数
				var ixin		# エリア内セル位置
				var ixout		# エリア外セル位置
				for i in range(cage[CAGE_IX_LIST].size()):
					var ix = cage[CAGE_IX_LIST][i]
					var x = ix % N_HORZ
					var y = ix / N_HORZ
					if x >= x0 && x < x0 + wd && y >= y0 && y < y0 + ht:	# エリア内
						if is_empty_cell(ix):		# セルが空欄
							ni += 1
							ixin = ix
						else:
							cage_sum_in[cx] += get_cell_numer(ix)
					else:	# エリア外
						if is_empty_cell(ix):		# セルが空欄
							no += 1
							ixout = cage[CAGE_IX_LIST][i]
						#else:
						#	cage_sum_out[cx] += get_cell_numer(ix)
				#var no = cage[CAGE_IX_LIST].size() - ni		# エリア外セル数
				if ni == 1 || no == 1:
					if cxio >= 0: return [-1, -1]
					cxio = cx
					nis = ni
					if ni == 1: ix0 = ixin
					else: ix0 = ixout
				elif ni > 1 && no > 1: return [-1, -1]
				else:
					if ni != 0: cage_sum_in[cx] = 0		# 空欄がエリア内にある場合
	if cxio < 0: return [-1, -1]
	var r = 21 * wd * ht / 6
	for c in range(cage_list.size()):
		if cage_processed[c] && c != cxio:
			#if !not_empty_cage[c]:
			if cage_sum_in[c] == 0:
				r -= cage_list[c][CAGE_SUM]
			else:
				r -= cage_sum_in[c]
	print("(%d %d %d %d)" % [x0, y0, wd, ht])
	if nis == 1:	# エリア内に1箇所だけ不定セルがある場合
		return [ix0, r]
	else:			# エリア内に複数箇所の不定セルがある場合
		return [ix0, cage_list[cxio][CAGE_SUM] - r]

func find_rule21():			# ルール21で決まるセルを探す
	for y in range(N_VERT):		# y 行をチェック
		var r = check_rule21(0, y, N_HORZ, 1)
		if r[0] >= 0: return r
	for x in range(N_HORZ):		# x 列をチェック
		var r = check_rule21(x, 0, 1, N_VERT)
		if r[0] >= 0: return r
	for y in range(3):
		for x in range(2):
			var r = check_rule21(x*3, y*2, 3, 2)
			if r[0] >= 0: return r
	var r = check_rule21(0, 0, N_HORZ, 2)
	if r[0] >= 0: return r
	r = check_rule21(0, 0, N_HORZ, 3)
	if r[0] >= 0: return r
	r = check_rule21(0, 4, N_HORZ, 2)
	if r[0] >= 0: return r
	r = check_rule21(0, 0, 2, N_VERT)
	if r[0] >= 0: return r
	r = check_rule21(0, 0, 3, N_VERT)
	if r[0] >= 0: return r
	r = check_rule21(4, 0, 2, N_VERT)
	if r[0] >= 0: return r
	return [-1, -1]
# 候補が２つしかないセルの組の片方の数字がロックされている箇所を探す
func find_locked_double():
	for ci in range(cage_list.size()):
		var cage = cage_list[ci]
		if cage[CAGE_SUM] == 0: continue
		if cage[CAGE_SUM] <= 4 || cage[CAGE_SUM] >= 10 && cage[CAGE_IX_LIST].size() == 2:
			if is_empty_cell(cage[CAGE_IX_LIST][0]) && is_empty_cell(cage[CAGE_IX_LIST][1]):
				var horz = abs(cage[CAGE_IX_LIST][0] - cage[CAGE_IX_LIST][1]) == 1
				var bits0 = 0
				var bits1 = 0
				if horz:	# ２セルケージが横
					var x0 = cage[CAGE_IX_LIST][0] % N_HORZ
					var x1 = cage[CAGE_IX_LIST][1] % N_HORZ
					for y in range(N_VERT):
						bits0 |= cell_bit[xyToIX(x0, y)]
						bits1 |= cell_bit[xyToIX(x1, y)]
					for y in range(N_VERT-1):
						if cage_ix[xyToIX(x0, y)] == cage_ix[xyToIX(x0, y+1)]:
							var cg = cage_list[cage_ix[xyToIX(x0, y)]]
							if cg[CAGE_IX_LIST].size() == 2:
								if cg[CAGE_SUM] == 3: bits0 |= BIT_1 | BIT_2
								elif cg[CAGE_SUM] == 4: bits0 |= BIT_1 | BIT_3
								elif cg[CAGE_SUM] == 10: bits0 |= BIT_4 | BIT_6
								elif cg[CAGE_SUM] == 11: bits0 |= BIT_5 | BIT_6
						if cage_ix[xyToIX(x1, y)] == cage_ix[xyToIX(x1, y+1)]:
							var cg = cage_list[cage_ix[xyToIX(x1, y)]]
							if cg[CAGE_IX_LIST].size() == 2:
								if cg[CAGE_SUM] == 3: bits1 |= BIT_1 | BIT_2
								elif cg[CAGE_SUM] == 4: bits1 |= BIT_1 | BIT_3
								elif cg[CAGE_SUM] == 10: bits1 |= BIT_4 | BIT_6
								elif cg[CAGE_SUM] == 11: bits1 |= BIT_5 | BIT_6
				else:	# ２セルケージが縦
					var y0 = cage[CAGE_IX_LIST][0] / N_HORZ
					var y1 = cage[CAGE_IX_LIST][1] / N_HORZ
					for x in range(N_VERT):
						bits0 |= cell_bit[xyToIX(x, y0)]
						bits1 |= cell_bit[xyToIX(x, y1)]
					for x in range(N_HORZ-1):
						if cage_ix[xyToIX(x, y0)] == cage_ix[xyToIX(x+1, y0)]:
							var cg = cage_list[cage_ix[xyToIX(x, y0)]]
							if cg[CAGE_IX_LIST].size() == 2:
								if cg[CAGE_SUM] == 3: bits0 |= BIT_1 | BIT_2
								elif cg[CAGE_SUM] == 4: bits0 |= BIT_1 | BIT_3
								elif cg[CAGE_SUM] == 10: bits0 |= BIT_4 | BIT_6
								elif cg[CAGE_SUM] == 11: bits0 |= BIT_5 | BIT_6
						if cage_ix[xyToIX(x, y1)] == cage_ix[xyToIX(x+1, y1)]:
							var cg = cage_list[cage_ix[xyToIX(x, y1)]]
							if cg[CAGE_IX_LIST].size() == 2:
								if cg[CAGE_SUM] == 3: bits1 |= BIT_1 | BIT_2
								elif cg[CAGE_SUM] == 4: bits1 |= BIT_1 | BIT_3
								elif cg[CAGE_SUM] == 10: bits1 |= BIT_4 | BIT_6
								elif cg[CAGE_SUM] == 11: bits1 |= BIT_5 | BIT_6
				if cage[CAGE_SUM] == 3:
					if (bits0 & BIT_1) != 0: return [cage[CAGE_IX_LIST][0], 2]
					if (bits0 & BIT_2) != 0: return [cage[CAGE_IX_LIST][0], 1]
					if (bits1 & BIT_1) != 0: return [cage[CAGE_IX_LIST][1], 2]
					if (bits1 & BIT_2) != 0: return [cage[CAGE_IX_LIST][1], 1]
				elif cage[CAGE_SUM] == 4:
					if (bits0 & BIT_1) != 0: return [cage[CAGE_IX_LIST][0], 3]
					if (bits0 & BIT_3) != 0: return [cage[CAGE_IX_LIST][0], 1]
					if (bits1 & BIT_1) != 0: return [cage[CAGE_IX_LIST][1], 3]
					if (bits1 & BIT_3) != 0: return [cage[CAGE_IX_LIST][1], 1]
				elif cage[CAGE_SUM] == 10:
					if (bits0 & BIT_6) != 0: return [cage[CAGE_IX_LIST][0], 4]
					if (bits0 & BIT_4) != 0: return [cage[CAGE_IX_LIST][0], 6]
					if (bits1 & BIT_6) != 0: return [cage[CAGE_IX_LIST][1], 4]
					if (bits1 & BIT_4) != 0: return [cage[CAGE_IX_LIST][1], 6]
				elif cage[CAGE_SUM] == 11:
					if (bits0 & BIT_6) != 0: return [cage[CAGE_IX_LIST][0], 5]
					if (bits0 & BIT_5) != 0: return [cage[CAGE_IX_LIST][0], 6]
					if (bits1 & BIT_6) != 0: return [cage[CAGE_IX_LIST][1], 5]
					if (bits1 & BIT_5) != 0: return [cage[CAGE_IX_LIST][1], 6]
	return [-1, -1]

func _on_hint_button_pressed():
	var bix = find_last_blank_cell_in_cage()
	print("last_blank_cell_in_cage: ", bix)
	#bix = check_rule21(0, 0, 6, 1)
	#bix = check_rule21(0, 0, 1, 6)
	#bix = check_rule21(0, 0, 1, 6)
	bix = find_rule21()
	print("rule21: ", bix)
	bix = find_locked_double()
	print("locked double: ", bix)
	pass # Replace with function body.
