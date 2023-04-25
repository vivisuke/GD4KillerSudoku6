extends Node2D

enum {
	CAGE_SUM = 0,			# ケージ内数字合計
	CAGE_IX_LIST,			# ケージ内セル位置配列
}
const CELL_WIDTH = 81				# 1セル表示幅
const CELL_WIDTH3 = CELL_WIDTH/3
const CELL_WIDTH4 = CELL_WIDTH/4

const INIT_N_COINS = 10
const DAYLY_N_COINS = 2
const TODAYS_QUEST_N_COINS = 3
const KEY_N_COINS = "nCoins"
const KEY_LOGIN_DATE = "LoginDate"

var env = {}			# 環境辞書
var settings = {}		# 設定辞書
var stats = []			# 各問題レベルごとの統計情報（問題クリア数、トータルタイム（単位：秒））
var nSolved = [0, 0, 0]		# 各問題集ごとの問題クリア数、[0] for 入門問題集
var qLevel = 0			# 問題レベル [0, 1, 2]
var qNumber = 0			# [1, 2^10] for 問題番号、0 for 非問題集
var qName = ""			# 問題名
var qRandom = true		# ランダム生成問題か？
var todaysQuest = false		# 今日の問題か？
var tqSolvedYMD = ""		# 今日の問題を解いた日付 "YYYY/MM/DD"
var tqSolvedSec = [-1, -1, -1]		# 各今日の問題クリアタイム、-1 for 未クリア
var tqConsYesterdayDays = 0			# 昨日までの連続クリア日数
var tqConsSolvedDays = 0			# 連続クリア日数
var tqMaxConsSolvedDays = 0			# 最大連続クリア日数
var elapsedTime = 0.0   	# 経過時間（単位：秒）

var show_hint_guide = false
var hint_pos : int = -1			# ヒントで数字が入る位置
var hint_bit : int = 0		# ヒントで入る数字ビット
var hint_type : int = -1
var candidates_bit = []		# 入力可能ビット論理和
var cell_bit = []			# 現在の状態
var saved_data = {}			# 自動保存データ

const AutoSaveFileName	= "user://KillerSudoku6_autosave.dat"		# 自動保存ファイル
const EnvFileName	= "user://KillerSudoku6_env.dat"				# 環境ファイル
const SettingsFileName	= "user://KillerSudoku6_stgs.dat"
const StatsFileName		= "user://KillerSudoku6_stats.dat"
const NSolvedFileName	= "user://KillerSudoku6_nSolved.dat"
const TodaysQuestFileName	= "user://KillerSudoku6_todaysQuest.dat"

func _ready():
	pass # Replace with function body.
#
func sec_to_MSStr(t):
	var sec = t % 60
	var mnt = t / 60
	return "%02d:%02d" % [mnt, sec]
#
func today_string():
	##var d = OS.get_da()
	var d = Time.get_date_dict_from_system()
	return "%04d/%02d/%02d" % [d["year"], d["month"], d["day"]]
func yesterday_string():
	var d = Time.get_datetime_dict_from_system()
	var u = Time.get_unix_time_from_datetime_dict(d)
	var y = Time.get_datetime_dict_from_unix_time (u - 60*60*24)	# 24時間前
	return "%04d/%02d/%02d" % [y["year"], y["month"], y["day"]]
	##var u = OS.get_unix_time_from_datetime(OS.get_datetime())
	##var y = OS.get_datetime_from_unix_time(u - 60*60*24)	# 24時間前
	##return "%04d/%02d/%02d" % [y["year"], y["month"], y["day"]]
#
func auto_load():
	if FileAccess.file_exists(AutoSaveFileName):
		saved_data = {}
	else:
		var file = FileAccess.open(AutoSaveFileName, FileAccess.READ)
		saved_data = file.get_var()
		file.close()
	return saved_data
func auto_save(solving : bool, board : Array):
	if !solving:
		saved_data = {}
	else:
		saved_data["solving"] = solving
		saved_data["board"] = board
		saved_data["today"] = today_string()
		saved_data["qLevel"] = qLevel
		saved_data["qNumber"] = qNumber
		saved_data["qName"] = qName
		saved_data["qRandom"] = qRandom
		saved_data["elapsedTime"] = elapsedTime
		saved_data["todaysQuest"] = todaysQuest
	var file = FileAccess.open(AutoSaveFileName, FileAccess.WRITE)
	file.store_var(saved_data)
	file.close()
func load_environment():
	if FileAccess.file_exists(EnvFileName):		# 設定ファイル
		var file = FileAccess.open(EnvFileName, FileAccess.READ)
		env = file.get_var()
		file.close()
	if !env.has(KEY_N_COINS): env[KEY_N_COINS] = INIT_N_COINS
	if env[KEY_N_COINS] < 0: env[KEY_N_COINS] = 0
	if env[KEY_N_COINS] == 0: env[KEY_N_COINS] = 50		# for Test
func save_environment():
	var file = FileAccess.open(EnvFileName, FileAccess.WRITE)
	file.store_var(env)
	file.close()
	pass
func load_settings():
	if FileAccess.file_exists(SettingsFileName):		# 設定ファイル
		var file = FileAccess.open(SettingsFileName, FileAccess.READ)
		settings = file.get_var()
		file.close()
	pass
func save_settings():
	var file = FileAccess.open(SettingsFileName, FileAccess.WRITE)
	file.store_var(settings)
	file.close()
	pass
func save_stats():
	var file = FileAccess.open(StatsFileName, FileAccess.WRITE)
	file.store_var(stats)
	file.close()
func load_stats():
	if FileAccess.file_exists(StatsFileName):		# 統計情報ファイル
		var file = FileAccess.open(StatsFileName, FileAccess.READ)
		stats = file.get_var()
		file.close()
		if stats.size() == 3:
			stats += [{}, {}, {}, ]
	else:
		stats = [{}, {}, {}, {}, {}, {}, ]		# [0] for 入門問題生成
	#print(stats)
func save_nSolved():
	var file = FileAccess.open(NSolvedFileName, FileAccess.WRITE)
	file.store_var(nSolved)
	file.close()
func load_nSolved():
	if FileAccess.file_exists(NSolvedFileName):		# 統計情報ファイル
		var file = FileAccess.open(NSolvedFileName, FileAccess.READ)
		nSolved = file.get_var()
		file.close()
	else:
		nSolved = [0, 0, 0]		# [0] for 入門問題集
func save_todaysQuest():
	var file = FileAccess.open(TodaysQuestFileName, FileAccess.WRITE)
	file.store_var([tqSolvedYMD, tqSolvedSec, tqConsSolvedDays, tqMaxConsSolvedDays])
	file.close()
func load_todaysQuest():
	if FileAccess.file_exists(TodaysQuestFileName):		# 統計情報ファイル
		var file = FileAccess.open(TodaysQuestFileName, FileAccess.READ)
		var data = file.get_var()
		print("today's data = ", data)
		tqSolvedYMD = data[0]
		tqSolvedSec = data[1]
		if data.size() >= 4:
			tqConsSolvedDays = data[2]
			tqMaxConsSolvedDays = data[3]
		else:
			tqConsSolvedDays = 0
			tqMaxConsSolvedDays = 0
		file.close()
	else:
		tqSolvedYMD = ""
		tqSolvedSec = [-1, -1, -1]
	pass
func memo_label_pos(px, py, h, v):
	return Vector2(px + CELL_WIDTH4*(h+1)-3, py + CELL_WIDTH3*(v+1))

#----------------------------------------------------------------------
class Board6x6:
	const N_VERT = 6
	const N_HORZ = 6
	const N_CELLS = N_HORZ * N_VERT
	const N_BOX_VERT = 2
	const N_BOX_HORZ = 3
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
	const LVL_BEGINNER = 0
	const LVL_EASY = 1
	const LVL_NORMAL = 2

	var qLevel					# 問題難易度
	var nAnswer
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

	var rng = RandomNumberGenerator.new()

	func _init():
		cell_bit.resize(N_CELLS)
		ans_num.resize(N_CELLS)
		#ans_bit.resize(N_CELLS)
		candidates_bit.resize(N_CELLS)
		#candidates_bit.fill(0)
		cage_ix.resize(N_CELLS)
		line_used.resize(N_HORZ)
		column_used.resize(N_HORZ)
		box_used.resize(N_HORZ)
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
	func get_cell_numer(ix) -> int:		# ix 位置に入っている数字の値を返す、0 for 空欄
		#if clue_labels[ix].text != "":
		#	return int(clue_labels[ix].text)
		#if input_labels[ix].text != "":
		#	return int(input_labels[ix].text)
		return bit_to_num(cell_bit[ix])
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
		for i in range(N_CELLS): ans_num[i] = bit_to_num(cell_bit[i])
		#print_ans()
		#print_ans_num()
		pass
	func gen_quest(qLvl: int, stxt:String):	# qLevel: 難易度、stxt: シード文字列
		qLevel = qLvl
		seed(stxt.hash())
		rng.set_seed(stxt.hash())
		while true:
			gen_ans()
			gen_cages()
			if qLevel == LVL_BEGINNER:
				if count_n_cell_cage(1) < 8:
					continue			# 再生成
			#	#split_2cell_cage()		# 1セルケージ数が４未満なら２セルケージを分割
			#el
			if qLevel == LVL_NORMAL:
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
		#update_cages_sum_labels()
		#solvedStat = false
		#g.elapsedTime = 0.0
		#ans_bit = cell_bit.duplicate()
		#print_ans()
		print_ans_num()
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
	func to_binstr(n, nbits) -> String:
		var t = ""
		var mask = 1 << (nbits-1)
		while mask != 0:
			t += "1" if (n&mask) != 0 else "0"
			mask >>= 1
		return t
	func print_candidates():
		var ix = 0
		for y in range(N_VERT):
			var lst = []
			for x in range(N_HORZ):
				#var n = "0b%06b" % candidates_bit[ix]
				var n = to_binstr(candidates_bit[ix], 6)
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
		print("cage_ix[]:")
		var ix = 0
		for y in range(N_VERT):
			var lst = []
			for x in range(N_HORZ):
				lst.push_back(cage_ix[ix])
				ix += 1
			print(lst)
		print("")
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
		#for i in range(N_CELLS): cage_labels[i].text = ""
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
		#$Board/CageGrid.cage_ix = cage_ix
		#$Board/CageGrid.queue_redraw()
	func sel_from_lst(ix, lst):		# lst からひとつを選ぶ
		if qLevel != LVL_NORMAL:
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
		#for i in range(N_CELLS): cage_labels[i].text = ""
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
		if qLevel < LVL_NORMAL:
			var cnt = 4 if qLevel == LVL_BEGINNER else 2
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
				#if qLevel == LVL_BEGINNER && i >= ar.size() - N_HORZ*2.2:
				#if qLevel == LVL_BEGINNER && rng.randf_range(0.0, 1.0) < 0.1:
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
					elif !lst2.is_empty() && qLevel != LVL_BEGINNER:	# ４近傍に２セルのケージがある場合
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
			#if sum != 0:
			#	cage_labels[lst.min()].text = str(sum)
			#for k in range(lst.size()): cage_ix[lst[k]] = ix
		quest_cages = cage_list
		#print_cages()
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
	func fill_1cell_cages():
		for ci in range(cage_list.size()):
			var cage = cage_list[ci]
			if cage[CAGE_IX_LIST].size() == 1:
				var ix = cage[CAGE_IX_LIST][0]
				cell_bit[ix] = num_to_bit(cage[CAGE_SUM])
				#input_labels[ix].text = str(cage[CAGE_SUM])
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
		#cage_labels[ix1].text = str(get_cell_numer(ix1))
		#cage_labels[ix2].text = str(get_cell_numer(ix2))
