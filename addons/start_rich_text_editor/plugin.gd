@tool
extends EditorPlugin


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	add_custom_type(
		"RichTextEditor",
		"Control",
		preload("res://addons/start_rich_text_editor/src/MultilineEditor.gd"),
		preload("res://addons/start_rich_text_editor/src/icon.svg")
		)
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
