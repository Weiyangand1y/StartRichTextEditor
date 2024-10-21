extends Control
var current_layout_y=0
var start_pos:Vector2
var rect_list:Array[Rect2]=[]
var editing_line=0

var selecting=false
var start_line=0
var start_posx=0

func _ready() -> void:
	start_pos=Vector2(0,0)
	current_layout_y=start_pos.y
	add_line()
	add_line()
	add_line()
	#big_select(0,2)
func add_line():
	var pl=PowerLineEdit.new()	
	pl.position=Vector2(start_pos.x,start_pos.y+current_layout_y)
	add_child(pl)
	var rect=pl.get_bound()
	rect.position+=Vector2(start_pos.x,start_pos.y+current_layout_y)
	current_layout_y+=rect.size.y
	rect_list.push_back(rect)
func get_click_line():
	var mpos=get_local_mouse_position()
	for i in rect_list.size():	
		if rect_list[i].has_point(mpos):
			return i
	return 0
func is_left_pressed(event: InputEvent):
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.is_pressed():
		return true
	return false
func is_left_released(event: InputEvent):
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.is_released():
		return true
	return false
func _input(event: InputEvent) -> void:
	if is_left_pressed(event):
		selecting=true
		start_line=get_click_line()
		start_posx=get_local_mouse_position().x-start_pos.x
	if event is InputEventMouseMotion and selecting:
		big_select(start_line,get_click_line(),start_posx,get_local_mouse_position().x-start_pos.x)
	if is_left_released(event):
		selecting=false
	if event.is_action_pressed("ui_text_newline"):
		insert_line()
	if event.is_action_pressed("ui_down"):
		move_down()
	if event.is_action_pressed("ui_up"):
		move_up()
func insert_line():
	var pl=PowerLineEdit.new()	
	add_child(pl)
	move_child(pl,editing_line+1)
	relayout()
	pass

func relayout():
	current_layout_y=start_pos.y
	for line:PowerLineEdit in get_children():
		line.position=Vector2(start_pos.x,start_pos.y+current_layout_y)
		var rect=line.get_bound()
		rect.position+=Vector2(start_pos.x,start_pos.y+current_layout_y)
		current_layout_y+=rect.size.y

func big_select(from_line,to_line,from_posx,to_posx):
	if from_line==to_line:
		return
	if from_line>to_line:
		var tmp1=from_line;from_line=to_line;to_line=tmp1
		var tmp2=from_posx;from_posx=to_posx;to_posx=tmp2
	for i in range(from_line+1,to_line):
		var line=get_child(i) as PowerLineEdit
		line.select_all()
	var fl=get_child(from_line) as PowerLineEdit
	var el=get_child(to_line) as PowerLineEdit
	fl.select_to_right(from_posx)
	fl.show_selection=true
	el.select_to_left(to_posx)
	el.show_selection=true
	pass
func move_up():
	var oline=get_child(editing_line) as PowerLineEdit
	var posx=oline.get_caret_posx()
	oline.unedit()
	editing_line-=1
	var line=get_child(editing_line) as PowerLineEdit
	line.caret_pos_set(Vector2(posx,32))
	line.edit()
	pass
func move_down():
	var oline=get_child(editing_line) as PowerLineEdit
	var posx=oline.get_caret_posx()
	oline.unedit()
	editing_line+=1
	var line=get_child(editing_line) as PowerLineEdit
	line.caret_pos_set(Vector2(posx,32))
	line.edit()
	pass
