extends Control
class_name PowerLineEdit
@export var font:Font
@export var show_bound:=false
signal text_change(tl:Array[Dictionary])
var show_selection:=false
var text_list:Array[Dictionary]=[
	{t="Hello  ",c=Color.PALE_GOLDENROD,bg=Color.DARK_GOLDENROD,fs=64},
	{key='C',s=Vector2(60,60)},
	{t="Helloh2World  ",c=Color.PINK,bg=Color.DARK_GOLDENROD,fs=32},
	{t="Hello World  ",c=Color.SKY_BLUE,bg=Color.ALICE_BLUE,fs=32},
	{key='C1',s=Vector2(60,60)},
	{key='C2',s=Vector2(60,60)},
	{t="Hell",c=Color.SKY_BLUE,bg=Color.ALICE_BLUE,fs=32},
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
		parse_test()
		
		)
func get_control_index(key:String):
	for i in text_list.size():
		if text_list[i].has('key') and text_list[i].key==key:
			return i
func add_control(key:String,control:Control):
	var ci=get_control_index(key)
	var rect=rect_list[ci]
	control.size=rect.size
	control.position=rect.position
	text_list[ci].c=control
	add_child(control)
func _ready() -> void:
	init()
	#select_all()
func init():
	start_init()
	layout()
	add_control('C',Button.new())
	add_control('C1',Button.new())
	add_control('C2',Button.new())
func get_control_rect(key:String)->Rect2:
	for i in text_list.size():
		if text_list[i].has('key') and text_list[i].key==key:
			return rect_list[i]
	return Rect2(0,0,0,0)

func pre_layout_control_rect(item:Dictionary):
	var rect=Rect2(Vector2(next_layout_x,start_position.y),item.s)
	rect_list.push_back(rect)
	h1=max(h1,item.s.y)
	next_layout_x+=item.s.x
	textline_list.push_back(TextLine.new())
func pre_layout_text(item:Dictionary):
	var t=TextLine.new()
	textline_list.push_back(t)
	t.add_string(item.t,font,item.fs)		
	var s=t.get_size()
	var d=t.get_line_descent()
	h1=max(h1,t.get_line_ascent())
	h2=max(h2,t.get_line_descent())
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
func render():
	var index=0
	if show_selection:
		for r in rl:
			draw_rect(r,Color.DARK_MAGENTA);
	for tl:TextLine in textline_list:
		var rect=rect_list[index] as Rect2
		if(text_list[index].has('t')):
			#draw_rect(rect,text_list[index].bg)
			tl.draw(
				get_canvas_item(),
				rect.position,
				text_list[index].c)
		index+=1
	pass
func is_text(index):
	return text_list[index].has('t')
func caret_pos_set(mpos):	
	for index in rect_list.size():
		var rect=rect_list[index] as Rect2
		if rect.has_point(mpos):
			#print('index: ',index)
			caret_block_index=index
			if !is_text(caret_block_index):
				break
			var t=TextLine.new()
			var start_position=rect.position
			t.add_string(text_list[index].t,font,text_list[index].fs)
			var h1=t.hit_test(mpos.x-start_position.x)
			#print('hit: ',h1)
			caret_col=h1
			t.clear()
			t.add_string(text_list[index].t.substr(0,h1),font,text_list[index].fs)
			var w=t.get_line_width()
			caret_pos_offsetx=w
func get_bound()->Rect2:
	return Rect2(start_position.x,start_position.y,next_layout_x-start_position.x,h1+h2)
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
func get_width(text:String,fs):
	var tl=TextLine.new()
	tl.add_string(text,font,fs)
	return tl.get_line_width()
func get_width2():
	var item=text_list[caret_block_index]
	if item.has('key'):return 0
	var text=item.t.substr(0,caret_col)
	var fs=item.fs
	var tl=TextLine.new()
	tl.add_string(text,font,fs)
	return tl.get_line_width()
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
#region 输入处理
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
	# If not editting, NOT Go Down!!!!
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
			print(s)
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
func caret_move_left():
	caret_col-=1
	var b=text_list[caret_block_index-1].has('key')
	if  caret_col==-1:
		caret_block_index-=1
		if b:
			caret_col=1
		else:
			caret_col=text_list[caret_block_index].t.length()
	refresh_caret()
func caret_move_right():
	caret_col+=1
	var b=text_list[caret_block_index].has('key')
	if(b or caret_col>=text_list[caret_block_index].t.length()):
		caret_col=0
		caret_block_index+=1
	refresh_caret()		
func insert(t:String):
	var item=text_list[caret_block_index]
	var text:String=item.t
	text=text.insert(caret_col,t)
	caret_col+=t.length()
	text_list[caret_block_index].t=text
	refresh_caret()
	update_ime_pos()
	emit_signal("text_change",text_list)
	relayout()

func relayout():
	textline_list.clear()
	rect_list.clear()
	next_layout_x=start_position.x
	layout()
	for i in text_list.size():
		if text_list[i].has('key') and text_list[i].has('c'):
			text_list[i]['c'].position=rect_list[i].position
	queue_redraw()
## 获取各个矩形
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
	if(i1.has('t')):
		var w1=get_width(i1.t.substr(0,f2),i1.fs)
		rl[0].position.x+=w1
		rl[0].size.x-=w1
	if(i2.has('t')):
		var w1=get_width(i2.t.substr(t2),i2.fs)
		rl[-1].size.x-=w1	
	pass
	
func select_all():
	show_selection=true
	select_start_index=0
	select_start_col=0
	select_end_index=text_list.size()-1
	select_end_col=text_list[select_end_index].t.length()
	select(
		select_start_index,  select_end_index,
		select_start_col,    select_end_col)
	pass
func select_to_left(posx):
	caret_pos_set(Vector2(posx,40))
	if !is_text(select_end_index):
		return
	select_end_col=text_list[select_end_index].t.length()
	print('--->',caret_block_index)
	select(caret_block_index, 0,          
			caret_col, 0)
	pass
func select_to_right(posx):
	caret_pos_set(Vector2(posx,40))
	select_end_col=text_list[select_end_index].t.length()
	print('--->',caret_block_index)
	select(caret_block_index, textline_list.size()-1,           
			caret_col, select_end_col)
	
#region 删除

## 删除,删除col-1位置
## 分为删除文字和方块
## 临界情况，caret col为0时
## 当遇到该情况，把caret_block_index-1,col=length-1
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
			caret_col=text_list[caret_block_index].t.length()
		delete_text()
	refresh_caret()
	relayout()
func delete_control_rect():
	if(text_list[caret_block_index].has('c')):
		text_list[caret_block_index].c.queue_free()
	text_list.remove_at(caret_block_index)
	caret_block_index-=1
	var item2=text_list[caret_block_index]
	if item2.has('t'):
		caret_col=item2.t.length()
	pass
func delete_text():
	var item=text_list[caret_block_index]
	var text:String=item.t	
	caret_move_left()
	print('remove: %d %d'%[caret_block_index,caret_col])
	text=text.erase(caret_col)
	item.t=text

	if(text.length()==0 and text_list.size()!=1):
		text_list.remove_at(caret_block_index)	
	#if(caret_col==0):
		#caret_move_left()
	pass
#endregion


func parse_test():
	for i in text_list.size():
		if(is_text(i)):
			var item_text=text_list[i].t as String
			if(item_text.contains('img')):
				var splits=item_text.split('img')
				text_list.remove_at(i)
				text_list.insert(i,{
					key='ib',s=Vector2(50,50)
				})
				text_list.insert(i+1,{
					t=splits[1],c=Color.PALE_GOLDENROD,bg=Color.DARK_GOLDENROD,fs=64
				})
				#add_control('ib',preload("res://image_button.tscn").instantiate())
	refresh_caret()
	relayout()

func update_ime_pos():
	DisplayServer.window_set_ime_position(
		global_position
		+rect_list[caret_block_index].position
		+caret_pos_offsetx*Vector2.RIGHT
		+get_bound().size.y*Vector2.DOWN
		)

func simple_copy():
	var s_start_index=select_start_index
	var s_end_index=select_end_index
	var s_start_col=select_start_col
	var s_end_col=select_end_col
	print('copy: %d %d -> %d %d'%[s_start_index,s_start_col,s_end_index,s_end_col])
	var text=''
	if(s_start_index==s_end_index and is_text(s_start_index)):
		var src_text=text_list[s_start_index].t as String
		text=text_list[s_start_index].t.substr(s_start_col,s_end_col-s_start_col)
		print("_%s_%s_"%[src_text,text])
	else:
		pass
	DisplayServer.clipboard_set(text)
	print(get_selection())

func get_caret_posx():
	return rect_list[caret_block_index].position.x+caret_pos_offsetx

func get_selection():
	var part=text_list.slice(select_start_index,select_end_index+1);
	if(part.size()>1):
		if is_text(select_start_index):
			part[0].t=part[0].t.substr(select_start_col)
		if is_text(select_end_index):
			part[-1].t=part[-1].t.substr(0,select_end_col)
	return part
func caret_move_end():
	var last_index=text_list.size()-1
	caret_block_index=last_index
	if is_text(last_index):
		caret_col=text_list[last_index].t.length()
	refresh_caret()
func caret_move_start():
	caret_block_index=0
	caret_col=0
	refresh_caret()
