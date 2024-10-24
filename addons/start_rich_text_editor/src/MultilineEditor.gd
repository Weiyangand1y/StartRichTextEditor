@icon("res://addons/start_rich_text_editor/src/icon.svg")
class_name RichTextEditor extends Control
var current_layout_y=0
var start_pos:Vector2
var rect_list:Array[Rect2]=[]
var editing_line=0
var selecting=false
var start_line=0
var start_posx=0

@export var default_font_color:=Color.WHITE
@export var default_font_size:=32
@export var default_bg_color:=Color.TRANSPARENT
@export var selection_color:=Color.WHEAT
@export var caret_color:=Color.BLACK
signal caret_change(p:PowerLineEdit)
var default_parser:Callable
var data:=[]
func _ready() -> void:
	start_pos=Vector2(0,0)
	current_layout_y=start_pos.y
	set_data()
	make_data_into_lines()
	set_control()
	relayout()
func set_control():
	pass
func set_data():
	pass
func add_control(line_index:int,key:String,control:Control):
	get_child(line_index).add_control(key,control)
func make_data_into_lines():
	for line_data in data:
		var line=add_line(line_data)
		if default_parser:
			line.parser=default_parser

func add_line(content=[])->PowerLineEdit:
	var pl=PowerLineEdit.new()	
	if !content.is_empty():
		pl.text_list=content
	pl.position=Vector2(start_pos.x,start_pos.y+current_layout_y)
	pl.default_bg_color=default_bg_color
	pl.default_font_color=default_font_color
	pl.default_font_size=default_font_size
	pl.selection_color=selection_color
	pl.connect("line_empty",func(line:PowerLineEdit):
		print('line empty')
		var index=line.get_index()
		editing_line=index-1
		var pre_line=get_children()[editing_line] as PowerLineEdit
		pre_line.edit()
		pre_line.caret_move_end()
		line.queue_free()
		await get_tree().process_frame
		relayout()
		)
	pl.connect("caret_change",func(p):
		emit_signal("caret_change",p))
	pl.connect("delete_line_start",func(line:PowerLineEdit):
		var index=line.get_index() 
		var pre_line=get_child(index-1) as PowerLineEdit
		var right=line.get_right()
		pre_line.text_list.append_array(right)
		pre_line.relayout()
		pre_line.edit()
		line.move_right_controls_to(pre_line)
		line.queue_free()
		relayout()
		)
	pl.connect("text_change",func(tl):
		relayout()
		)
	add_child(pl)
	var rect=pl.get_bound()
	rect.position+=Vector2(start_pos.x,start_pos.y+current_layout_y)
	current_layout_y+=rect.size.y
	rect_list.push_back(rect)
	return pl
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
func _process(delta: float) -> void:
	if selecting:
		big_select(start_line,get_click_line(),start_posx,get_local_mouse_position().x-start_pos.x)
func _input(event: InputEvent) -> void:
	if is_left_pressed(event):
		selecting=true
		start_line=get_click_line()
		editing_line=start_line
		start_posx=get_local_mouse_position().x-start_pos.x
	if is_left_released(event):
		selecting=false
	if event.is_action_pressed("ui_text_newline"):
		insert_line()
	if event.is_action_pressed("ui_down"):
		move_down()
	if event.is_action_pressed("ui_up"):
		move_up()
func insert_line():
	var current_line=get_child(editing_line) as PowerLineEdit
	var right=current_line.get_right()
	
	var line=add_line()
	line.text_list=right
	line.caret_move_start()
	line.relayout()
	current_line.move_right_controls_to(line)
	current_line.remove_right()
	current_line.unedit()
	
	
	move_child(line,editing_line+1)
	
	line.relayout()
	relayout()
	pass

func relayout():
	current_layout_y=start_pos.y
	var max_width=0
	for line:PowerLineEdit in get_children():
		line.position=Vector2(start_pos.x,start_pos.y+current_layout_y)
		var rect=line.get_bound()
		rect.position+=Vector2(start_pos.x,start_pos.y+current_layout_y)
		current_layout_y+=rect.size.y
		max_width=max(max_width,rect.size.x)
	custom_minimum_size=Vector2(max_width,current_layout_y)

func big_select(from_line,to_line,from_posx,to_posx):
	if from_line==to_line:
		return
	for line:PowerLineEdit in get_children():
		line.show_selection=false
	if from_line>to_line:
		var tmp1=from_line;from_line=to_line;to_line=tmp1
		var tmp2=from_posx;from_posx=to_posx;to_posx=tmp2
	for i in range(from_line+1,to_line):
		var line=get_child(i) as PowerLineEdit
		line.select_all()
	var fl=get_child(from_line) as PowerLineEdit
	var el=get_child(to_line) as PowerLineEdit

	fl.show_selection=true
	fl.select_to_right(from_posx)
	el.show_selection=true
	el.select_to_left(to_posx)	
	pass
func move_up():
	selecting=false
	if editing_line==0:return
	var oline=get_child(editing_line) as PowerLineEdit
	var posx=oline.get_caret_posx()
	oline.unedit()
	editing_line-=1
	var line=get_child(editing_line) as PowerLineEdit
	line.caret_pos_set(Vector2(posx,32))
	line.edit()
	pass
func move_down():
	if editing_line==get_children().size()-1:return
	var oline=get_child(editing_line) as PowerLineEdit
	var posx=oline.get_caret_posx()
	oline.unedit()
	editing_line+=1
	var line=get_child(editing_line) as PowerLineEdit
	line.caret_pos_set(Vector2(posx,32))
	line.edit()
	pass
