extends Panel
var editing_line:PowerLineEdit
var editing_index=0
func _ready() -> void:
	%RichTextEditor.connect("caret_change",update_component)
	$FontColor.connect("color_changed",func(new_color:Color):
		var item=editing_line.text_list[editing_index] as Dictionary
		editing_line.text_list[editing_index].font_color=new_color
		editing_line.relayout()
		editing_line.queue_redraw()
		)
	$BgColor.connect("color_changed",func(new_color:Color):
		var item=editing_line.text_list[editing_index] as Dictionary
		editing_line.text_list[editing_index].bg_color=new_color
		editing_line.relayout()
		editing_line.queue_redraw()
		)
	$FontSize.connect("value_changed",func(v):
		var item=editing_line.text_list[editing_index] as Dictionary
		editing_line.text_list[editing_index].font_size=v
		editing_line.relayout()
		%RichTextEditor.relayout()
		$FontSize/SpinBox.value=v
		)
	$FontSize/SpinBox.connect("value_changed",func(v):
		var item=editing_line.text_list[editing_index] as Dictionary
		editing_line.text_list[editing_index].font_size=v
		editing_line.relayout()
		%RichTextEditor.relayout()
		$FontSize.value=v
		)
func update_component(line:PowerLineEdit):
	var item=line.text_list[line.caret_block_index] as Dictionary
	if !line.is_text(line.caret_block_index): return
	$FontColor.color=item.get('font_color',line.default_font_color)
	$BgColor.color=item.get('bg_color',line.default_bg_color)
	editing_line=line
	editing_index=line.caret_block_index
	$FontSize/SpinBox.value=item.get('font_size',line.default_font_size)
	$FontSize.value=item.get('font_size',line.default_font_size)
	pass
