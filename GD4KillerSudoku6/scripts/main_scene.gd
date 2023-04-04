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
const TILE_EMPHASIZE = 0				# 強調カーソル（薄ピンク）
const TILE_CURSOR = 1
#const TILE_LTPINK = 1				# 強調カーソル（薄ピンク）
#const TILE_LTBLUE = 1				# 強調カーソル（薄青）
#const TILE_LTORANGE = 2				# 強調カーソル（薄橙）
#const TILE_PINK = 3					# 強調カーソル（薄ピンク）
const COLOR_INCORRECT = Color.RED
const COLOR_DUP = Color.RED
const COLOR_CLUE = Color.BLACK
#const COLOR_INPUT = Color("#2980b9")	# VELIZE HOLE
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

# Called when the node enters the scene tree for the first time.
func _ready():
	init_labels()
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
	gen_ans()
	pass # Replace with function body.

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
	return "%d" % bit_to_num(b)
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
			label.text = "%d" % ((x+y)%11 + 1)
			$Board.add_child(label)
			# 入力数字用ラベル
			label = Label.new()
			input_labels.push_back(label)
			label.add_theme_color_override("font_color", Color.BLACK)
			label.add_theme_font_size_override("font_size", 60)
			label.position = Vector2(px+32, py + 4)
			label.text = "%d" % ((x+y)%6 + 1)
			$Board.add_child(label)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
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
			input_labels[ix].text = "%d" % n
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
