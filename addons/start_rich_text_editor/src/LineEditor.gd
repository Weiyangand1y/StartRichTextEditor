extends Control
class_name PowerLineEdit
@export var font:Font
@export var show_bound:=false
signal text_change(tl:Array[Dictionary])
var show_selection:=false
@export var default_font_size:=32
@export var default_bg_color:=Color.TRANSPARENT
@export var default_font_color:=Color.WHITE
@export var selection_color:=Color.WHEAT
var text_list:=[
	{text="Hello  ",font_color=Color.PALE_GOLDENROD,font_size=48},
	{key='C0',size=Vector2(60,60)},
	{text="Helloh2World  ",font_color=Color.PINK},
	{text="Hello World  ",font_color=Color.SKY_BLUE},
	{key='C1',size=Vector2(60,60)},
	{text="Hell",font_color=Color.SKY_BLUE,font_size=32},
]

#region State Data
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
		parse()		
		)
func _ready() -> void:
	init()
	#select_all()
func init():
	start_init()
	layout()
	add_control('C0',Button.new())
	add_control('C1',Button.new())
	add_control('C2',Button.new())
#endregion
# about control--------------------------------------------------
#region Control Rect
func get_control_index(key:String):
	for i in text_list.size():
		if text_list[i].has('key') and text_list[i].key==key:
			return i
	return -1
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
	rect_list.push_back(Rect2(next_layout_x,start_position.y,s.x,s.y-d))
	next_layout_x+=s.x
func layout():
	for item in text_list:
		if item.has('key'):
			pre_layout_control_rect(item)
		else:
			pre_layout_text(item)
	for i in rect_list.size():
		if text_list[i].has('key'):continue
		var d=textline_list[i].get_line_ascent()
		rect_list[i].position.y=h1-d+start_position.y
func relayout():
	textline_list.clear()
	rect_list.clear()
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
		+get_bound().size.y*Vector2.DOWN
		)
func draw_caret():
	var rect=rect_list[caret_block_index]
	var caret_pos=rect.position+Vector2.RIGHT*caret_pos_offsetx
	var color=Color.YELLOW
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
func _input(event: InputEvent) -> void:		
	if(is_left_pressed(event)):	
		on_select=true	
		var mpos=get_local_mouse_position()
		caret_pos_set(mpos)
		ssc=caret_col
		ssi=caret_block_index
		update_ime_pos()
		if get_bound().has_point(mpos):
			edit()
		elif mpos.y>0 and mpos.y<get_bound().size.y and mpos.x>0:
			edit()
			caret_move_end()
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
			#print(s)
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
#endregion
# caret ------------------------------------------------------------
#region caret
func caret_pos_set(mpos):	
	for index in rect_list.size():
		var rect=rect_list[index] as Rect2
		if rect.has_point(mpos):
			#print('index: ',index)
			caret_block_index=index
			if !is_text(caret_block_index):
				break
			var text=TextLine.new()
			var start_position=rect.position
			text.add_string(
				text_list[index].text,
				font,
				text_list[index].get('font_size',default_font_size)
				)
			var h1=text.hit_test(mpos.x-start_position.x)
			#print('hit: ',h1)
			caret_col=h1
			text.clear()
			text.add_string(
				text_list[index].text.substr(0,h1),
				font,
				text_list[index].get('font_size',default_font_size)
				)
			var w=text.get_line_width()
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
		caret_col=0
		caret_block_index+=1
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
func get_selection():
	var part=text_list.slice(select_start_index,select_end_index+1);
	if(part.size()>1):
		if is_text(select_start_index):
			part[0].text=part[0].text.substr(select_start_col)
		if is_text(select_end_index):
			part[-1].text=part[-1].text.substr(0,select_end_col)
	return part
func select(from,to,f2,t2):
	#print('select from %d %d to %d %d '%[from,f2,to,t2]) 
	# 修改前后排序
	if from>to:
		var tmp=from;from=to;to=tmp;
		var tmp2=f2;f2=t2;t2=tmp2
	select_start_index=from
	select_start_col=f2
	select_end_index=to
	select_end_col=t2
	# 添加选中背景
	rl=rect_list.slice(from,to+1)
	#print(rl) 
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
	if !is_text(select_end_index):
		return
	select_end_col=text_list[select_end_index].text.length()
	#print('--->',caret_block_index)
	select(caret_block_index, 0,          
			caret_col, 0)
	pass
func select_to_right(posx):
	caret_pos_set(Vector2(posx,40))
	select_end_col=text_list[select_end_index].text.length()
	#print('--->',caret_block_index)
	select(caret_block_index, textline_list.size()-1,           
			caret_col, select_end_col)
#endregion
#delete--------------------------------------------------------
#region delete

func back_delete():
	if caret_col==0 and caret_block_index==0:return
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
	caret_move_left()
	#print('remove: %d %d'%[caret_block_index,caret_col])
	text=text.erase(caret_col)
	item.text=text

	if(text.length()==0 and text_list.size()!=1):
		text_list.remove_at(caret_block_index)	
	#if(caret_col==0):
		#caret_move_left()
	pass
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
	parse_test()
func parse_test():
	for i in text_list.size():
		if(is_text(i)):
			var item_text=text_list[i].text as String
			if(item_text.contains('img')):
				var splits=item_text.split('img')
				text_list.remove_at(i)
				text_list.insert(i,{
					key='ib',size=Vector2(64,64)
				})
				text_list.insert(i+1,{
					text=splits[1],font_color=Color.PALE_GOLDENROD,bg_color=Color.DARK_GOLDENROD,font_size=64
				})
				var btn=TextureButton.new()
				btn.stretch_mode=TextureButton.STRETCH_KEEP_ASPECT
				btn.texture_normal=preload("res://addons/start_rich_text_editor/src/icon.svg")
				add_control('ib',btn)
	refresh_caret()
	relayout()
#endregion


# copy & paste ---------------------------------------------------------
#region copy & paste
func simple_copy():
	var s_start_index=select_start_index
	var s_end_index=select_end_index
	var s_start_col=select_start_col
	var s_end_col=select_end_col
	var text=''
	if(s_start_index==s_end_index and is_text(s_start_index)):
		var src_text=text_list[s_start_index].text as String
		text=text_list[s_start_index].text.substr(s_start_col,s_end_col-s_start_col)

	else:
		pass
	DisplayServer.clipboard_set(text)
	#print(get_selection())
#endregion


#other get-------------------------------------------------------------------------
func is_text(index):
	return text_list[index].has('text')
func get_bound()->Rect2:
	return Rect2(start_position.x,start_position.y,next_layout_x-start_position.x,h1+h2)

func get_width(text:String,font_size):
	var tl=TextLine.new()
	tl.add_string(text,font,font_size)
	return tl.get_line_width()
func get_width2():
	var item=text_list[caret_block_index]
	if item.has('key'):return 0
	var text=item.text.substr(0,caret_col)
	var font_size=item.get('font_size',default_font_size)
	var tl=TextLine.new()
	tl.add_string(text,font,font_size)
	return tl.get_line_width()
