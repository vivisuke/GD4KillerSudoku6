extends Object

enum {
	CAGE_SUM = 0,			# ケージ内数字合計
	CAGE_IX_LIST,			# ケージ内セル位置配列
}
const CAGE_TABLE = [
	[	# for 2セルケージ
		0b000011, 0b000101, 0b001111,						# for 3, 4, 5
		0b011011, 0b111111, 0b110110, 0b111100, 0b101000, 	# for 6, 7, ... 10
		0b110000, 											# for 11
	],
	[	# for 3セルケージ
		0b000000, 0b000000, 0b000000,						# for 3, 4, 5
		0b000111, 0b001011, 0b011111, 0b111111, 0b111111,	# for 6, 7, ... 10
		0b111111, 0b111111, 0b111110, 0b110100, 0b111000,	# for 11, 12, ... 15
	],
	[	# for 4セルケージ
		0b000000, 0b000000, 0b000000,						# for 3, 4, 5
		0b000000, 0b000000, 0b000000, 0b000000, 0b001111,	# for 6, 7, ... 10
		0b010111, 0b111111, 0b111111, 0b111111, 0b111111,	# for 11, 12, ... 15
		0b111111, 0b111111, 0b111111, 0b111010, 0b111100,	# for 16, 17, 18
	],
]

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
var nSpaces					# 空欄箇所数
var cert_posnum				# 確定箇所・数字
var nAnswer
var ans_num = []			# 解答の各セル数値、1～N_HORZ
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
func dupcopy(s):
	ans_num = s.ans_num.duplicate()
	cell_bit = s.cell_bit.duplicate()
	cage_list = s.cage_list.duplicate()
	cage_ix = s.cage_ix.duplicate()
	candidates_bit = s.candidates_bit.duplicate()

#	return bd
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
func is_empty_cell(ix) -> bool:
	return cell_bit[ix] == 0
	#return input_labels[ix].text == ""
func get_cell_numer(ix) -> int:		# ix 位置に入っている数字の値を返す、0 for 空欄
	#if clue_labels[ix].text != "":
	#	return int(clue_labels[ix].text)
	#if input_labels[ix].text != "":
	#	return int(input_labels[ix].text)
	return bit_to_num(cell_bit[ix])
func put_num(ix, num):
	cell_bit[ix] = num_to_bit(num)
	#nSpaces -= 1
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
	print("seed = ", stxt)
	#seed(stxt.hash())
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
	for ix in range(N_CELLS): cell_bit[ix] = 0
	fill_1cell_cages()
	#update_cages_sum_labels()
	#solvedStat = false
	#g.elapsedTime = 0.0
	#ans_bit = cell_bit.duplicate()
	#print_ans()
	#for ix in range(N_CELLS): cell_bit[ix] = 0		# 全セルを空欄に
	print_ans_num()
func print_cells():
	print("cell_bit[]:")
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
func print_cages_ex():		# 罫線でケージ形状表示
	for y in range(N_VERT):
		var txt = ""
		for x in range(N_HORZ):
			var ix = xyToIX(x, y)
			txt += "+" + ("-" if y == 0 || cage_ix[ix-N_HORZ] != cage_ix[ix] else " ")
		print(txt+"+")
		txt = ""
		for x in range(N_HORZ):
			var ix = xyToIX(x, y)
			txt += "|" if x == 0 || cage_ix[ix-1] != cage_ix[ix] else " "
			txt += " "
		print(txt+"|")
	var txt = ""
	for x in range(N_HORZ): txt += "+-"
	print(txt+"+")
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
		#print_ans_num()
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
	nSpaces = N_CELLS
	for ci in range(cage_list.size()):
		var cage = cage_list[ci]
		if cage[CAGE_IX_LIST].size() == 1:
			var ix = cage[CAGE_IX_LIST][0]
			cell_bit[ix] = num_to_bit(cage[CAGE_SUM])
			#input_labels[ix].text = str(cage[CAGE_SUM])
			nSpaces -= 1
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
func find_last_blank_cell_in_cage() -> bool:		# ケージ内の最後の空白セルを探す
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
			cert_posnum = [bix, sum]
			return true
	return false
func check_fullhouse(x0:int, y0:int, wd:int, ht:int) -> bool:
	var bits = 0
	var bix = -1		# 空欄位置
	for v in range(ht):
		for h in range(wd):
			var ix = xyToIX(x0+h, y0+v)
			if cell_bit[ix] == 0:
				if bix >= 0: return false
				bix = ix
			else:
				bits |= cell_bit[ix]
	if bix < 0: return false		# 空欄無し
	var n = bit_to_num(~bits & ALL_BITS)
	cert_posnum = [bix, n]
	return true
func find_fullhouse() -> bool:		# 縦・横・ブロック内の最後の空白セルを探す
	for y in range(N_VERT):
		if check_fullhouse(0, y, N_HORZ, 1): return true
	for x in range(N_HORZ):
		if check_fullhouse(x, 0, 1, N_HORZ): return true
	for v in range(3):
		for h in range(2):
			if check_fullhouse(h*3, v*2, 3, 2): return true
	return false
# (x0, y0)-(x0+wd, y0+ht) 範囲にルール21を適用できるかどうかチェック
# return: [数字が決まる位置, 入る数字]
func check_rule21(x0:int, y0:int, wd:int, ht:int) -> bool:
	var cage_processed = []				# ケージ処理済みフラグ
	cage_processed.resize(cage_list.size())
	cage_processed.fill(false)
	var cage_sum_in = []				# 各ケージのエリア内数字合計
	cage_sum_in.resize(cage_list.size())
	cage_sum_in.fill(0)
	var cage_sum_out = cage_sum_in.duplicate()	# 各ケージのエリア外数字合計
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
						else:
							cage_sum_out[cx] += get_cell_numer(ix)
				#var no = cage[CAGE_IX_LIST].size() - ni		# エリア外セル数
				if ni == 1 || no == 1:
					if cxio >= 0: return false
					cxio = cx
					nis = ni
					if ni == 1: ix0 = ixin
					else: ix0 = ixout
				elif ni > 1 && no > 1: return false
				else:
					if ni != 0: cage_sum_in[cx] = 0		# 空欄がエリア内にある場合
	if cxio < 0: return false
	var r = 21 * wd * ht / 6
	for c in range(cage_list.size()):
		if cage_processed[c] && c != cxio:
			#if !not_empty_cage[c]:
			if cage_sum_in[c] == 0:
				r -= cage_list[c][CAGE_SUM] - cage_sum_out[c]
			else:
				r -= cage_sum_in[c]
	print("(%d %d %d %d)" % [x0, y0, wd, ht])
	if nis == 1:	# エリア内に1箇所だけ不定セルがある場合
		cert_posnum = [ix0, r - cage_sum_in[cxio]]
	else:			# エリア内に複数箇所の不定セルがある場合
		cert_posnum = [ix0, cage_list[cxio][CAGE_SUM] - cage_sum_out[cxio] - r]
	return true

func find_rule21() -> bool:			# ルール21で決まるセルを探す
	for y in range(N_VERT):		# y 行をチェック
		if check_rule21(0, y, N_HORZ, 1): return true
	for x in range(N_HORZ):		# x 列をチェック
		if check_rule21(x, 0, 1, N_VERT): return true
	for y in range(3):
		for x in range(2):
			if check_rule21(x*3, y*2, 3, 2): return true
	if check_rule21(0, 0, N_HORZ, 2): return true
	if check_rule21(0, 0, N_HORZ, 3): return true
	if check_rule21(0, 4, N_HORZ, 2): return true
	if check_rule21(0, 0, 2, N_VERT): return true
	if check_rule21(0, 0, 3, N_VERT): return true
	if check_rule21(4, 0, 2, N_VERT): return true
	return false
# 候補が２つしかないセルの組の片方の数字がロックされている箇所を探す
func find_locked_double() -> bool:
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
					if (bits0 & BIT_1) != 0:
						cert_posnum = [cage[CAGE_IX_LIST][0], 2]; return true
					if (bits0 & BIT_2) != 0:
						cert_posnum = [cage[CAGE_IX_LIST][0], 1]; return true
					if (bits1 & BIT_1) != 0:
						cert_posnum = [cage[CAGE_IX_LIST][1], 2]; return true
					if (bits1 & BIT_2) != 0:
						cert_posnum = [cage[CAGE_IX_LIST][1], 1]; return true
				elif cage[CAGE_SUM] == 4:
					if (bits0 & BIT_1) != 0:
						cert_posnum = [cage[CAGE_IX_LIST][0], 3]; return true
					if (bits0 & BIT_3) != 0:
						cert_posnum = [cage[CAGE_IX_LIST][0], 1]; return true
					if (bits1 & BIT_1) != 0:
						cert_posnum = [cage[CAGE_IX_LIST][1], 3]; return true
					if (bits1 & BIT_3) != 0:
						cert_posnum = [cage[CAGE_IX_LIST][1], 1]; return true
				elif cage[CAGE_SUM] == 10:
					if (bits0 & BIT_6) != 0:
						cert_posnum = [cage[CAGE_IX_LIST][0], 4]; return true
					if (bits0 & BIT_4) != 0:
						cert_posnum = [cage[CAGE_IX_LIST][0], 6]; return true
					if (bits1 & BIT_6) != 0:
						cert_posnum = [cage[CAGE_IX_LIST][1], 4]; return true
					if (bits1 & BIT_4) != 0:
						cert_posnum = [cage[CAGE_IX_LIST][1], 6]; return true
				elif cage[CAGE_SUM] == 11:
					if (bits0 & BIT_6) != 0:
						cert_posnum = [cage[CAGE_IX_LIST][0], 5]; return true
					if (bits0 & BIT_5) != 0:
						cert_posnum = [cage[CAGE_IX_LIST][0], 6]; return true
					if (bits1 & BIT_6) != 0:
						cert_posnum = [cage[CAGE_IX_LIST][1], 5]; return true
					if (bits1 & BIT_5) != 0:
						cert_posnum = [cage[CAGE_IX_LIST][1], 6]; return true
	return false
# 裸のシングルを探す
# ただし、候補数字がすでに計算されているものとする
func find_naked_single() -> bool:
	for ix in range(N_CELLS):
		var c = candidates_bit[ix]
		if c != 0 && ((c-1)&c) == 0:
			cert_posnum = [ix, bit_to_num(c)]
			return true
	return false
#func find_hidden_single_test(c: Array):
#	var b1 = 0			# ビットの数が1
#	var b2 = 0			# ビットの数が2以上
#	for i in range(c.size()):
#		b2 |= c[i] & b1
#		b1 ^= c[i]
#	b1 &= ~b2
#	print("b1 = ", to_binstr(b1, 6))
# 指定エリア内で候補数字数を数え、一箇所だけの位置・数字を返す
func find_hidden_single_sub(x0:int, y0:int, wd:int, ht:int) -> bool:
	#var b0 = 0b111111	# ビットの数が0
	var b1 = 0			# ビットの数が1
	var b2 = 0			# ビットの数が2以上
	#print("b1, b2 = 0x%x, 0x%x" % [b1, b2])
	for v in range(ht):
		for h in range(wd):
			var c = candidates_bit[xyToIX(x0+h, y0+v)]
			b2 |= c & b1
			b1 ^= c
			#b0 ^= c
			#print("c, b1, b2 = 0x%x, 0x%x, 0x%x" % [c, b1, b2])
	b1 &= ~b2
	#if b1 == 0 || ((b1-1)&b1) != 0: return false
	if b1 == 0: return false
	b1 &= -b1		# 最下位のビットのみ取り出す
	for v in range(ht):
		for h in range(wd):
			var ix = xyToIX(x0+h, y0+v)
			var c = candidates_bit[ix]
			if (c & b1) != 0:
				cert_posnum = [ix, bit_to_num(b1)]
				return true
	return false		# ここには来ないはずだが、念のため
# 隠れたシングルを探す
# ただし、候補数字がすでに計算されているものとする
func find_hidden_single() -> bool:
	for y in range(N_VERT):
		if find_hidden_single_sub(0, y, N_HORZ, 1): return true
	for x in range(N_HORZ):
		if find_hidden_single_sub(x, 0, 1, N_VERT): return true
	for y in range(3):
		for x in range(2):
			if find_hidden_single_sub(x*3, y*2, 3, 2): return true
	return false
func init_candidates():		# cell_bit から各セルの候補数字計算
	for i in range(N_CELLS):
		candidates_bit[i] = ALL_BITS if cell_bit[i] == 0 else 0
	for y in range(N_VERT):
		for x in range(N_HORZ):
			var b = cell_bit[xyToIX(x, y)]
			if b != 0:
				for t in range(N_HORZ):
					candidates_bit[xyToIX(t, y)] &= ~b
					candidates_bit[xyToIX(x, t)] &= ~b
				var x0 = x - x % 3		# 3x2ブロック左上位置
				var y0 = y - y % 2
				for v in range(N_BOX_VERT):
					for h in range(N_BOX_HORZ):
						candidates_bit[xyToIX(x0 + h, y0 + v)] &= ~b
	pass
func cage_bits(cage):
	var sum = cage[CAGE_SUM]
	var nc = cage[CAGE_IX_LIST].size()		# セル数
	if nc == 1:
		return num_to_bit(sum)
	else:
		return CAGE_TABLE[nc-2][sum-3]
func remove_candidates_in_cage():	# 各ケージで不可能な候補数字を消す
	for cx in range(cage_list.size()):
		var cage = cage_list[cx]
		var b = cage_bits(cage)
		for i in range(cage[CAGE_IX_LIST].size()):
			candidates_bit[cage[CAGE_IX_LIST][i]] &= b
# 2セルケージで、相手がいない候補数字を消す
# return: 候補数字を消したか？
func remove_lonely_candidates() -> bool:
	var rmvd = false
	for cx in range(cage_list.size()):
		var cage = cage_list[cx]
		if cage[CAGE_IX_LIST].size() == 2:	# 2セルケージ
			if get_cell_numer(cage[CAGE_IX_LIST][0]) == 0 && get_cell_numer(cage[CAGE_IX_LIST][1]) == 0:
				var cb0 = candidates_bit[cage[CAGE_IX_LIST][0]]
				var cb1 = candidates_bit[cage[CAGE_IX_LIST][1]]
				var mask = 1
				for n in range(1, N_HORZ+1):
					if (cb0 & mask) != 0:
						var b = num_to_bit(cage[CAGE_SUM] - bit_to_num(mask))
						if (cb1 & b) == 0:	# 相手がいない場合
							cb0 ^= mask
							rmvd = true
					if (cb1 & mask) != 0:
						var b = num_to_bit(cage[CAGE_SUM] - bit_to_num(mask))
						if (cb0 & b) == 0:	# 相手がいない場合
							cb1 ^= mask
							rmvd = true
					mask <<= 1
				candidates_bit[cage[CAGE_IX_LIST][0]] = cb0
				candidates_bit[cage[CAGE_IX_LIST][1]] = cb1
	return rmvd
# より簡単な解法から順に確定箇所・数字を探す
# return: 適用できる解法の難易度、0 for 未発見
func find_certain_posnum() -> int:
	if find_last_blank_cell_in_cage(): return 1
	if find_fullhouse(): return 1
	if find_locked_double(): return 2
	init_candidates()				# 可能候補数字計算 → candidates_bit[]
	remove_candidates_in_cage()		# 各ケージで不可能な候補数字を消す
	if find_hidden_single(): return 3
	if find_naked_single(): return 3
	if find_rule21(): return 5
	remove_lonely_candidates()		# 相手がいない候補数字を削除
	if find_hidden_single(): return 10
	if find_naked_single(): return 10
	return 0
# 問題難易度計算
# return: 難易度（整数）、-1 for 初級テクだけでは解けない
func calc_difficulty() -> int:
	var bd2 = self
	bd2.dupcopy(self)
	var sum = 0		# 難易度
	while bd2.nSpaces != 0:
		var d = bd2.find_certain_posnum()
		if d == 0: return 0
		sum += d
		bd2.put_num(cert_posnum[0], cert_posnum[1])
		bd2.nSpaces -= 1
	return sum
