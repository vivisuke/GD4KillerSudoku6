extends ColorRect

const N_VERT = 6
const N_HORZ = 6
const N_CELLS = N_HORZ * N_VERT
const CELL_WIDTH = 81
const WD = 11

var cage_ix = []

func _ready():
	if true:	# for Test
		cage_ix.resize(N_CELLS)
		for i in range(N_CELLS): cage_ix[i] = i % 4
	pass # Replace with function body.

#func print_cages():
#	#for i in range(cage_list.size()):
#	#	print(cage_list[i])
#	print("cage_ix[]:")
#	var ix = 0
#	for y in range(N_VERT):
#		var lst = []
#		for x in range(N_HORZ):
#			lst.push_back(cage_ix[ix])
#			ix += 1
#		print(lst)
#	print("")
func _draw():
	if cage_ix == []: return
	#print("CageGrid.draw()")
	#print_cages()
	var col = Color.ORANGE
	var ix = 0
	for y in range(N_VERT):
		var py = y * CELL_WIDTH
		for x in range(N_HORZ):
			var px = x * CELL_WIDTH
			if x == 0 || cage_ix[ix-1] != cage_ix[ix]:
				draw_line(Vector2(px, py-WD/2), Vector2(px, py+CELL_WIDTH+WD/2), col, WD)
			if y == 0 || cage_ix[ix-N_HORZ] != cage_ix[ix]:
				draw_line(Vector2(px-WD/2, py), Vector2(px+CELL_WIDTH+WD/2, py), col, WD)
			ix += 1
	draw_line(Vector2(CELL_WIDTH*N_HORZ, 0), Vector2(CELL_WIDTH*N_HORZ, CELL_WIDTH*N_VERT+WD/2), col, WD)
	draw_line(Vector2(0, CELL_WIDTH*N_VERT), Vector2(CELL_WIDTH*N_HORZ+WD/2, CELL_WIDTH*N_VERT), col, WD)
	pass
