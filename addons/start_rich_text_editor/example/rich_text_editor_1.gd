extends RichTextEditor
func set_data() -> void:
	data =	[[
	{text="The sun was setting ",font_color=Color.PINK,bg_color=Color.hex(0xf3f2c0ff),font_size=32},
	{text="over the rolling hills ",font_color=Color.SKY_BLUE,bg_color=Color.hex(0xcbe0deff),font_size=32},
	{text="the rolling hills",font_color=Color.SKY_BLUE,bg_color=Color.from_string("#694a87",Color.TRANSPARENT),font_size=32},
	],
	
	[
	{text="green meadow  ",font_color=Color.hex(0x8cbfc2ff),font_size=48},
	{key='c1',size=Vector2(80,60),type='button',prop={text='.button.',color='#112299'}},
	{text="Helloh2World  ",font_color=Color.hex(0xa4c263ff)},
	{text="Hello World  ",font_color=Color.SKY_BLUE},
	{key='c2',size=Vector2(60,60),type='image',prop={path="res://docs/icon.png"}},
	{text="Hell",font_color=Color.SKY_BLUE,font_size=32},
	],
	
	[
	{text="There is a line ",font_color=Color.hex(0xbd757eff),font_size=32},
	{text="  water  ",font_color=Color.SKY_BLUE,bg_color=Color.ALICE_BLUE,font_size=32},
	{text=" grass",font_color=Color.SEA_GREEN,font_size=32},
	{key='btn1',size=Vector2(64,64),type='button',prop={text='button',color='#c0d470',bdc='#67835c',fc='#000000'}}
	]]
	default_parser=parse_test2
class ControlFactory:
	static var table={
		button=ButtonFactory,
		image=ImageFactory
		}
	static func create(type:String,props:Dictionary)->Control:
		return table[type].create(props)
		
	class ButtonFactory:
		static func create(props:Dictionary):
			var btn=Button.new()
			btn.text=props.get('text','')
			if props.has('color'):
				var stylebox=StyleBoxFlat.new()
				stylebox.bg_color=Color.from_string(props.color,Color.NAVAJO_WHITE)
				stylebox.set_corner_radius_all(12)
				stylebox.set_border_width_all(1)
				stylebox.border_color=Color.from_string(props.get('bdc',''),Color.NAVAJO_WHITE)
				btn.add_theme_color_override('font_color',Color.from_string(props.get('fc',''),Color.NAVAJO_WHITE))
				btn.add_theme_stylebox_override('normal',stylebox)
			return btn
	class ImageFactory:
		static func create(props:Dictionary):
			var texture_rect=TextureRect.new()
			texture_rect.texture=load(props.path)
			texture_rect.stretch_mode=TextureRect.STRETCH_SCALE
			texture_rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			return texture_rect
func set_control():
	var index=0
	for line:Array in data:
		var index2=0
		for item:Dictionary in line:
			if item.has('type'):
				var control=ControlFactory.create(item.type,item.prop)
				control.size=item.size
				control.position=get_child(index).rect_list[index2].position
				item.c=control
				get_child(index).add_child(control)
			index2+=1
		index+=1
	
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
