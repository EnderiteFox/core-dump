class_name GameChat
extends Control


signal opened
signal closed


@onready var chat_content: RichTextLabel = %ChatContent
@onready var chat_line_edit: LineEdit = %ChatLineEdit


@export var escape_menu: EscapeMenu


func _ready() -> void:
	var game_instance := GameInstance.get_current(self)
	game_instance.new_chat_message.connect(_on_chat_message)
	chat_line_edit.text_submitted.connect(_on_send_message)
	escape_menu.opened.connect(close)
	
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_chat"):
		if is_open():
			close()
		else:
			open()
		get_viewport().set_input_as_handled()
	
	
func _on_chat_message(message: String) -> void:
	if not chat_content.get_parsed_text().is_empty():
		chat_content.newline()
	chat_content.append_text(message)
	
	
func _on_send_message(message: String) -> void:
	if message.is_empty():
		return
	
	var game_instance := GameInstance.get_current(self)
	game_instance.send_chat_message.rpc(message)
	chat_line_edit.clear()
	
	
func is_open() -> bool:
	return self.visible


func open() -> void:
	if is_open() or escape_menu.is_open():
		return
	
	self.visible = true
	chat_line_edit.grab_focus()
	opened.emit()
	
	
func close() -> void:
	if not is_open():
		return
	self.visible = false
	chat_line_edit.release_focus()
	closed.emit()
