extends RichTextEditor
func set_data() -> void:
	data =	[[
	{text="There is a mountain",font_color=Color.PINK,bg_color=Color.DARK_GOLDENROD,font_size=32},
	{text="Hello World  ",font_color=Color.SKY_BLUE,bg_color=Color.ALICE_BLUE,font_size=32},
	{text="Hello",font_color=Color.SKY_BLUE,bg_color=Color.ALICE_BLUE,font_size=32},
	],
	
	[
	{text="Hello  ",font_color=Color.PALE_GOLDENROD,font_size=48},
	{key='c1',size=Vector2(60,60)},
	{text="Helloh2World  ",font_color=Color.PINK},
	{text="Hello World  ",font_color=Color.SKY_BLUE},
	{key='c2',size=Vector2(60,60)},
	{text="Hell",font_color=Color.SKY_BLUE,font_size=32},
	],
	
	[
	{text="There is a line ",font_color=Color.PINK,font_size=32},
	{text="  water  ",font_color=Color.SKY_BLUE,bg_color=Color.ALICE_BLUE,font_size=32},
	{text=" grass",font_color=Color.SEA_GREEN,font_size=32},
	{key='btn1',size=Vector2(64,64)}
	]]
	default_parser=parse_test
	
func set_control():
	add_control(1,'c1',Button.new())
	add_control(1,'c2',Button.new())
	var button=Button.new()
	button.text='A button'
	add_control(2,'btn1',button)
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
