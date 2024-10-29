extends Control

class InspectorFactory:
	static var table={
		button=ButtonFactory,
		image=ImageFactory
		}
	static func create(item):
		return table[item.type].create(item)
		pass
	class ButtonFactory:
		static func create(item):
			var container=VBoxContainer.new()
			var color_picker1=ColorPickerButton.new()
			color_picker1.custom_minimum_size=Vector2(40,40)
			color_picker1.connect("color_changed",func(v):
				var button=item.c as Button
				button.add_theme_color_override('font_color',v)
				item.fc=v
				)
			container.add_child(color_picker1)
			return container
	class ImageFactory:
		static func create(item:Dictionary):
			var container=VBoxContainer.new()
			var line_edit=LineEdit.new()
			return container
			pass
func show_inspector(rich_text_editor,i,j):
	#clear()
	var line=rich_text_editor.get_child(i) as PowerLineEdit
	var block_index=line.control_to_block_index(j)
	var item=line.text_list[block_index]
	#print(item)
	#add_child(InspectorFactory.create(item))
	if item.type=='image':
		$Image.show()
		$Image.editting_image_block=item
	pass
func clear():
	for c in get_children():
		c.queue_free()
