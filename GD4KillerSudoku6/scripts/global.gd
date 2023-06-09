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

