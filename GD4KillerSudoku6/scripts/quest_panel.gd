extends ReferenceRect


signal pressed(num)

var number

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_q_number(num):
	number = num
	$Button.text = "#%06d" % num
func set_enabled(f):
	$Button.disabled = !f
func set_icon(icon):
	$Button.set_button_icon(icon)
func solved_set_visible(b):
	if b:
		$Solved.show()
	else:
		$Solved.hide()
func _on_button_pressed():
	print("emit_signal('previous', %d)" % number)
	emit_signal("pressed", number)
	pass # Replace with function body.
