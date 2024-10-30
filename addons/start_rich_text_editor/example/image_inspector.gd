extends Control
var editting_block:Dictionary:
	set(new_value):
		editting_block=new_value
		$Size/X/SpinBox.value=new_value.size.x
		$Size/Y/SpinBox.value=new_value.size.y
		pass

func on_path_submit(new_text):
	var path=new_text
	var texture_rect=editting_block.c as TextureRect
	texture_rect.texture=ImageTexture.create_from_image(Image.load_from_file(path))
	editting_block.prop.path=path
	pass
func _ready() -> void:
	$Size/X/SpinBox.connect("value_changed",func(v):
		editting_block.size.x=v
		editting_block.c.size.x=v
		)
	$Size/Y/SpinBox.connect("value_changed",func(v):
		editting_block.size.y=v
		editting_block.c.size.y=v
		)
	$Path/Button.connect("pressed",func():
		$FileDialog.popup_centered()
		)
	$FileDialog.connect("file_selected",func(path):
		on_path_submit(path)
		)
