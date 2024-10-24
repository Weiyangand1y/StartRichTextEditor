extends RichTextEditor
func set_data() -> void:
	data =	[[
	{text="The sun was setting ",font_color=Color.PINK,bg_color=Color.hex(0xf3f2c0ff),font_size=32},
	{text="over the rolling hills ",font_color=Color.SKY_BLUE,bg_color=Color.hex(0xcbe0deff),font_size=32},
	{text="the rolling hills",font_color=Color.SKY_BLUE,bg_color=Color.from_string("#694a87",Color.TRANSPARENT),font_size=32},
	],
	
	[
	{text="green meadow  ",font_color=Color.hex(0x8cbfc2ff),font_size=48},
	{key='c1',size=Vector2(60,60)},
	{text="Helloh2World  ",font_color=Color.hex(0xa4c263ff)},
	{text="Hello World  ",font_color=Color.SKY_BLUE},
	{key='c2',size=Vector2(60,60)},
	{text="Hell",font_color=Color.SKY_BLUE,font_size=32},
	],
	
	[
	{text="There is a line ",font_color=Color.hex(0xbd757eff),font_size=32},
	{text="  water  ",font_color=Color.SKY_BLUE,bg_color=Color.ALICE_BLUE,font_size=32},
	{text=" grass",font_color=Color.SEA_GREEN,font_size=32},
	{key='btn1',size=Vector2(64,64)}
	]]
	default_parser=parse_test2
	
func set_control():
	add_control(1,'c1',Button.new())
	add_control(1,'c2',Button.new())
	var button=Button.new()
	button.text='A button'
	add_control(2,'btn1',button)
func parse_replace_to(line:PowerLineEdit,str:String,to:Dictionary):
	for i in line.text_list.size():
		if(line.is_text(i)):
			var item=line.text_list[i] as Dictionary
			var item_text=item.text as String
			if(item_text.contains(str)):
				var left_item=item.duplicate()
				var right_item=item.duplicate()
				var splits=item_text.split(str)
				left_item.text=splits[0]
				right_item.text=splits[1]
				line.text_list.remove_at(i)
				line.text_list.insert(i,left_item)
				line.text_list.insert(i+1,to)
				line.text_list.insert(i+2,right_item)
				if to.has('key') and to.has('c'):
					line.relayout()
					line.add_child(to.c)
	line.refresh_caret()
	line.relayout()
func parse_test2(line:PowerLineEdit):
	#parse_replace_to(line,'we',{text='HHH'})
	var btn=Button.new()
	btn.text='click'
	btn.size=Vector2(56,56)
	parse_replace_to(line,'btn',{key='',size=Vector2.ONE*56,c=btn})
	var text_rect=TextureRect.new()
	text_rect.texture=preload("res://docs/explanatory_diagram.png")
	text_rect.stretch_mode=TextureRect.STRETCH_SCALE
	text_rect.scale=Vector2.ONE*0.5
	text_rect.size=Vector2.ONE*56
	parse_replace_to(line,'img',{key='',size=Vector2(128,128),c=text_rect})
func parse_test(line:PowerLineEdit):
	for i in line.text_list.size():
		if(line.is_text(i)):
			var item_text=line.text_list[i].text as String
			if(item_text.contains('img')):
				var splits=item_text.split('img')
				line.text_list.remove_at(i)
				line.text_list.insert(i,{
					key='ib',size=Vector2(64,64)
				})
				line.text_list.insert(i+1,{
					text=splits[1],font_size=32
				})
				var btn=TextureRect.new()
				btn.texture=preload("res://addons/start_rich_text_editor/src/icon.svg")			
				btn.stretch_mode=TextureRect.STRETCH_SCALE
				btn.size=Vector2.ONE*64
				line.relayout()
				line.add_control('ib',btn)
	line.refresh_caret()
	line.relayout()
