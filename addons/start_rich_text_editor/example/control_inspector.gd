extends Control
@onready var inpesctor_list={
	image=$Image,
	button=$Button
}
func show_inspector(rich_text_editor,i,j):
	#clear()
	var line=rich_text_editor.get_child(i) as PowerLineEdit
	var block_index=line.control_to_block_index(j)
	var item=line.text_list[block_index]
	#print(item)
	for c in $".".get_children():
		c.hide()
	var inspector=inpesctor_list[item.type] as Control
	inspector.show()
	inspector.editting_block=item
	pass
func clear():
	for c in get_children():
		c.queue_free()
