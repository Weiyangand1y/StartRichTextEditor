extends Control
var editting_block:Dictionary:
	set(new_value):
		editting_block=new_value
		$BG/ColorPickerButton.color=editting_block.prop.color
		$FontColor/ColorPickerButton.color=editting_block.prop.fc

func _ready() -> void:
	$BG/ColorPickerButton.connect("color_changed",func(v):
		var btn=editting_block.c as Button
		editting_block.prop.color=v
		var box=btn.get_theme_stylebox("normal") as StyleBoxFlat
		box.bg_color=v
		)
	$FontColor/ColorPickerButton.connect("color_changed",func(v):
		var btn=editting_block.c as Button
		editting_block.prop.fc=v
		btn.add_theme_color_override("font_color",v)
		)
	$BDC/ColorPickerButton.connect("color_changed",func(v):
		var btn=editting_block.c as Button
		editting_block.prop.bdc=v
		var box=btn.get_theme_stylebox("normal") as StyleBoxFlat
		box.border_color=v
		)
		
