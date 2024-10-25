extends Control
class_name PowerLineEdit
@export var font:Font
@export var show_bound:=false
## emit when text change
signal text_change(tl:Array[Dictionary])
## emit when line is empty
signal line_empty(p:PowerLineEdit)
## emit when caret at the beginning of the line
signal delete_line_start(p:PowerLineEdit)
signal caret_change(p:PowerLineEdit)
var show_selection:=false
@export var default_font_size:=32
@export var default_bg_color:=Color.TRANSPARENT
@export var default_font_color:=Color.WHITE
@export var selection_color:=Color.WHEAT
@export var caret_color:=Color.BLACK
var text_list:=[
	{text=' '}
]
var parser:Callable
#region State Data
var tmp_textline=TextLine.new()
# layout state
var rect_list:Array[Rect2]=[]
var textline_list:Array[TextLine]=[];
var next_layout_x:=50;
var h1:=0;var h2:=0
var start_position:Vector2

# caret state
@export var blink_time:=0.5
var tween:Tween
var transparent:=0.0
var caret_block_index:=0
var caret_col:=0
var caret_pos_offsetx:=0

# selection state
var on_select:=false
var select_start_col:=0
var select_start_index:=0
var select_end_col:=0
var select_end_index=0
var ssi=0
var ssc=0
var rl:Array[Rect2]=[]
# editing
var editing:=false
#endregion
#init--------------------------------------------------------------
#region init
func start_init():
	connect("line_empty",func(a):
		print('empty'))
	DisplayServer.window_set_ime_active(true)
	if !font:
		font=SystemFont.new()
	start_position=Vector2(0,0)
	next_layout_x=start_position.x
	tween=create_tween()	
	tween.tween_method(func(v):
		transparent=v
		,0.0,1.0,blink_time)
	tween.tween_method(func(v):
		transparent=v
		,1.0,0.0,blink_time)
	tween.set_loops()
	connect("text_change",func(a):
		custom_minimum_size.x=get_bound().size.x
		parse()		
		)
func _ready() -> void:
	init()
	#select_all()
func init():
	start_init()
	layout()
#endregion
# about control--------------------------------------------------
#region Control Rect
func get_control_index(key:String):
	return text_list.find_custom(func(item):
		return item.has('key') and item.key==key
	)
func add_control(key:String,control:Control):
	var ci=get_control_index(key)
	if ci==-1:return
	var rect=rect_list[ci]
	control.size=rect.size
	control.position=rect.position
	text_list[ci].c=control
	add_child(control)

func get_control_rect(key:String)->Rect2:
	for i in text_list.size():
		if text_list[i].has('key') and text_list[i].key==key:
			return rect_list[i]
	return Rect2(0,0,0,0)
#endregion
# layout--------------------------------------------------------------
#region layout
func pre_layout_control_rect(item:Dictionary):
	var rect=Rect2(
		Vector2(next_layout_x,start_position.y),
		item.size)
	rect_list.push_back(rect)
	h1=max(h1,item.size.y)
	next_layout_x+=item.size.x
	textline_list.push_back(TextLine.new())
func pre_layout_text(item:Dictionary):
	var text=TextLine.new()
	textline_list.push_back(text)
	text.add_string(item.text,font,item.get('font_size',default_font_size))		
	var s=text.get_size()
	var d=text.get_line_descent()
	h1=max(h1,text.get_line_ascent())
	h2=max(h2,text.get_line_descent())
	var rect=Rect2(
		next_layout_x,start_position.y,
		s.x,          s.y-d)
	rect_list.push_back(rect)
	next_layout_x+=s.x
func layout():
	for item in text_list:
		if item.has('key'):
			pre_layout_control_rect(item)
		else:
			pre_layout_text(item)
	for i in rect_list.size():
		if text_list[i].has('key'):
			rect_list[i].position.y=start_position.y+h1-rect_list[i].size.y
		else:
			var d=textline_list[i].get_line_ascent()
			rect_list[i].position.y=h1-d+start_position.y
	custom_minimum_size=get_bound().size
func relayout():
	textline_list.clear()
	rect_list.clear()
	h1=0
	h2=0
	next_layout_x=start_position.x
	layout()
	for i in text_list.size():
		if text_list[i].has('key') and text_list[i].has('c'):
			text_list[i]['c'].position=rect_list[i].position
	queue_redraw()
#endregion
# render--------------------------------------------------------------
#region render
func render():
	var index=0
	# draw bg
	for i in text_list.size():
		var rect=rect_list[i] as Rect2
		rect.size.y=h1+h2-3
		rect.position.y=3
		if(text_list[i].has('text')):
			draw_rect(rect,text_list[i].get('bg_color',default_bg_color))
	# draw selection
	if show_selection:
		for r in rl:
			draw_rect(r,selection_color);
	# draw text
	for tl:TextLine in textline_list:
		var rect=rect_list[index] as Rect2
		if(text_list[index].has('text')):
			tl.draw(
				get_canvas_item(),
				rect.position,
				text_list[index].get('font_color',default_font_color))
		index+=1
	pass
func _draw() -> void:
	render()
	if editing:draw_caret()
	if show_bound:
		for r in rect_list:
			draw_rect(r,Color.LIGHT_SEA_GREEN,false,1);
		draw_rect(get_bound().grow(5),Color.RED,false)

func _process(delta: float) -> void:
	queue_redraw()
func refresh_caret():
	caret_pos_offsetx=get_width2()
func update_ime_pos():
	DisplayServer.window_set_ime_position(
		global_position
		+rect_list[caret_block_index].position
		+caret_pos_offsetx*Vector2.RIGHT
		+get_bound().size.y*2*Vector2.DOWN
		)
func draw_caret():
	var rect=rect_list[caret_block_index]
	var caret_pos=rect.position+Vector2.RIGHT*caret_pos_offsetx
	var color=caret_color
	color.a=transparent
	draw_line(
		caret_pos,
		caret_pos+rect.size.y*Vector2.DOWN,
		color,2)
	pass
#endregion

# edit enter & out ------------------------------------------------------
#region enter & out
func edit():
	editing=true
	show_selection=true
	select_start_col=0
	select_start_index=0
	rl.clear()
	update_ime_pos()
	for c:Control in get_children():
		c.release_focus()
func unedit():
	editing=false
	show_selection=false
#endregion
#region input
# input-------------------------------------------------------------
func is_left_pressed(event: InputEvent):
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.is_pressed():
		return true
	return false
func is_left_released(event: InputEvent):
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.is_released():
		return true
	return false

func is_in():	
	if get_parent() is RichTextEditor:
		var p=get_parent() as RichTextEditor
		var max_width=get_parent_area_size().x
		if p.scroll_container:
			if !(p.scroll_container.get_global_rect().has_point(get_global_mouse_position())):
				return false
	return true

func _input(event: InputEvent) -> void:		
	if(is_left_pressed(event)):
		if !is_in():return
		var mpos=get_local_mouse_position()	
		caret_pos_set(mpos)
		ssc=caret_col
		ssi=caret_block_index
		update_ime_pos()
		if get_bound().has_point(mpos):
			edit()
			emit_signal("caret_change",self)
			on_select=true
		elif mpos.y>0 and mpos.y<get_bound().size.y and mpos.x>0:
			var is_to_edit=true
#			when in multiline, caret to end
			if get_parent() is RichTextEditor:
				var p=get_parent() as RichTextEditor
				var max_width=get_parent_area_size().x
				if mpos.x>max_width:
					is_to_edit=false
			if is_to_edit:
				edit()
				caret_move_end()
			on_select=true
		else: unedit()
		queue_redraw()
	# ---------------------------------------------
	# If not editing, NOT Go Down!!!!
	if !editing:return
	if(event is InputEventMouseMotion):
		if on_select:
			caret_pos_set(get_local_mouse_position())
			select(ssi,caret_block_index,ssc,caret_col)
			queue_redraw()
		pass
	if is_left_released(event):
		on_select=false
	
	if(event.is_action_pressed("ui_text_backspace")):
		back_delete()
	if(event is InputEventKey):
		var uc=event.unicode
		if(uc>256 or (uc>=32 and uc<=126)):
			var s=String.chr(uc)
			insert(s)
	if(event.is_action_pressed("ui_left")):
		caret_move_left()
	if(event.is_action_pressed("ui_right")):
		caret_move_right()
	if(event.is_action_pressed("ui_paste")):
		insert(DisplayServer.clipboard_get())
	if(event.is_action_pressed("ui_copy")):
		simple_copy()
	if(event.is_action_pressed("ui_end")):
		caret_move_end()
	if(event.is_action_pressed("ui_home")):
		caret_move_start()
	if(event is InputEventKey):
		event=event as InputEventKey
		if event.alt_pressed and event.keycode==KEY_D:
			split_text_block()
#endregion
# caret ------------------------------------------------------------
#region caret
func caret_pos_set(mpos):	
	if mpos.x>get_bound().size.x:
		caret_move_end()
		return
	for index in rect_list.size():
		var rect=rect_list[index] as Rect2
		if mpos.x>rect.position.x and mpos.x<rect.position.x+rect.size.x:
			caret_block_index=index
			if !is_text(caret_block_index):
				break
			tmp_textline.clear()
			var start_position=rect.position
			tmp_textline.add_string(
				text_list[index].text,
				font,
				text_list[index].get('font_size',default_font_size)
				)
			var h1=tmp_textline.hit_test(mpos.x-start_position.x)
			#print('hit: ',h1)
			caret_col=h1
			tmp_textline.clear()
			tmp_textline.add_string(
				text_list[index].text.substr(0,h1),
				font,
				text_list[index].get('font_size',default_font_size)
				)
			var w=tmp_textline.get_line_width()
			caret_pos_offsetx=w
			
func caret_move_left():
	caret_col-=1
	var b=text_list[caret_block_index-1].has('key')
	if  caret_col==-1:
		caret_block_index-=1
		if b:
			caret_col=1
		else:
			caret_col=text_list[caret_block_index].text.length()
	refresh_caret()
func caret_move_right():
	caret_col+=1
	var b=text_list[caret_block_index].has('key')
	if(b or caret_col>=text_list[caret_block_index].text.length()):		
		if caret_block_index<text_list.size()-1:
			caret_block_index+=1
			caret_col=0
	refresh_caret()		
func caret_move_end():
	var last_index=text_list.size()-1
	caret_block_index=last_index
	if is_text(last_index):
		caret_col=text_list[last_index].text.length()
	refresh_caret()
func caret_move_start():
	caret_block_index=0
	caret_col=0
	refresh_caret()
func get_caret_posx()->float:
	return rect_list[caret_block_index].position.x+caret_pos_offsetx
#endregion

# select-----------------------------------------------------------
#region select
# condition: 0,1,1+
func get_selection():
	var part=text_list.slice(select_start_index,select_end_index+1);
	part=part.duplicate(true)
	if part.size()==1:
		part[0].text=part[0].text.substr(select_start_col,select_end_col-select_start_col)
	elif(part.size()>1):
		if is_text(select_start_index):
			part[0].text=part[0].text.substr(select_start_col)
		if is_text(select_end_index):
			part[-1].text=part[-1].text.substr(0,select_end_col)
	return part
func select(from,to,f2,t2):
	#print('select from %d %d to %d %d '%[from,f2,to,t2]) 
	# 修改前后排序 swap
	if from>to:
		var tmp=from;from=to;to=tmp;
		var tmp2=f2;f2=t2;t2=tmp2
	select_start_index=from
	select_start_col=f2
	select_end_index=to
	select_end_col=t2
	# 添加选中背景 selection background rect
	rl=rect_list.slice(from,to+1)
	# the first and last
	var i1=text_list[from]
	var i2=text_list[to]
	if(i1.has('text')):
		var w1=get_width(i1.text.substr(0,f2),i1.get('font_size',default_font_size))
		rl[0].position.x+=w1
		rl[0].size.x-=w1
	if(i2.has('text')):
		var w1=get_width(i2.text.substr(t2),i2.get('font_size',default_font_size))
		rl[-1].size.x-=w1	
	pass
	
func select_all():
	show_selection=true
	select_start_index=0
	select_start_col=0
	select_end_index=text_list.size()-1
	select_end_col=text_list[select_end_index].text.length()
	select(
		select_start_index,  select_end_index,
		select_start_col,    select_end_col)
	pass
func select_to_left(posx):
	caret_pos_set(Vector2(posx,40))
	if !is_text(caret_block_index):
		return
	select_start_index=0
	select_start_col=0
	select_end_index=caret_block_index
	select_end_col=caret_col
	
	select(select_start_index, select_end_index,      
			select_start_col,select_end_col)
	pass
func select_to_right(posx):
	#print(posx)
	caret_pos_set(Vector2(posx,40))
	select_start_index=caret_block_index
	#print(caret_block_index)
	select_start_col=caret_col
	select_end_index=textline_list.size()-1
	select_end_col=text_list[select_end_index].text.length()	
	select(select_start_index, select_end_index,           
			select_start_col, select_end_col)
#endregion
#delete--------------------------------------------------------
#region delete
# problems: 
# 1. text or control
# 2. block begin
# 3. line begin
func back_delete():
	if caret_col==0 and caret_block_index==0:
		emit_signal("delete_line_start",self)
		return
	var to_left=false
	if caret_col==0:
		caret_block_index-=1
		to_left=true
	if !is_text(caret_block_index):
		delete_control_rect()
	else:
		if to_left:
			caret_col=text_list[caret_block_index].text.length()
		delete_text()
	refresh_caret()
	relayout()
	emit_signal("text_change",text_list)
func delete_control_rect():
	if(text_list[caret_block_index].has('c')):
		text_list[caret_block_index].c.queue_free()
	text_list.remove_at(caret_block_index)
	caret_block_index-=1
	var item2=text_list[caret_block_index]
	if item2.has('text'):
		caret_col=item2.text.length()
	pass
func delete_text():
	var item=text_list[caret_block_index]
	var text:String=item.text	
	
	text=text.erase(caret_col-1)
	item.text=text
	if(text.length()==0 and text_list.size()!=1):
		text_list.remove_at(caret_block_index)	
			
	if(text.length()==0 and text_list.size()==1):
		line_empty.emit(self)
		return
	caret_move_left()
	
#endregion
#insert---------------------------------------------------------
#region insert text
func insert(text:String):
	var item=text_list[caret_block_index]
	var t:String=item.text
	t=t.insert(caret_col,text)
	caret_col+=text.length()
	text_list[caret_block_index].text=t
	refresh_caret()
	update_ime_pos()
	emit_signal("text_change",text_list)
	relayout()
#endregion
# parser----------------------------------------------------------------
#region parser
func parse():
	if parser:parser.call(self)
#endregion


# copy & paste ---------------------------------------------------------
#region copy & paste
func simple_copy():
	var text=''
	var item_list=get_selection() as Array[Dictionary]
	for item in item_list:
		if item.has('text'):
			text+=item.text
	DisplayServer.clipboard_set(text)
	print(text)
#endregion


#other get-------------------------------------------------------------------------
func is_text(index):
	return text_list[index].has('text')
func get_bound()->Rect2:
	return Rect2(
		start_position.x,start_position.y,
		next_layout_x-start_position.x,h1+h2)

func get_width(text:String,font_size):
	tmp_textline.clear()
	tmp_textline.add_string(text,font,font_size)
	return tmp_textline.get_line_width()
## get text width from start to col in block index
func get_width2():
	var item=text_list[caret_block_index]
	if item.has('key'):return item.size.x
	var text=item.text.substr(0,caret_col)
	var font_size=item.get('font_size',default_font_size)
	tmp_textline.clear()
	tmp_textline.add_string(text,font,font_size)
	return tmp_textline.get_line_width()
# new a line  -------------------------------------
#region To new a line
func get_right():
	var t1=text_list.slice(caret_block_index).duplicate(true)
	if t1.is_empty(): return []
	if 'text' in t1[0]:
		t1[0].text=t1[0].text.substr(caret_col)
	return t1
func remove_right():
	text_list=text_list.slice(0,caret_block_index+1)
	if 'text' in text_list[-1]:
		var text=text_list[-1].text
		text_list[-1].text=text.substr(0,caret_col)
	relayout()
func push_front(new_text_list:Array):
	new_text_list.append_array(textline_list)
	text_list=new_text_list
	relayout()
func move_right_controls_to(toline:PowerLineEdit):
	var items=text_list.slice(caret_block_index).filter(func(item):return item.has('key') and item.has('c'))
	for item in items:
		var control_node=item.c as Control
		remove_child(control_node)
		toline.add_control(item.key,control_node)
#endregion
func split_text_block():
	if !is_text(caret_block_index):
		return
	var item=text_list[caret_block_index] as Dictionary
	var item1=item.duplicate()
	var item2=item.duplicate()
	item1.text=(item.text as String).substr(0,caret_col)
	item2.text=item.text.substr(caret_col,item.text.length()-caret_col)
	text_list.remove_at(caret_block_index)
	text_list.insert(caret_block_index,item1)
	text_list.insert(caret_block_index+1,item2)
	relayout()
