class_name GameChat
extends Control


@onready var chat_content: RichTextLabel = %ChatContent
@onready var chat_line_edit: LineEdit = %ChatLineEdit


func _ready() -> void:
	var game_instance := GameInstance.get_current(self)
	game_instance.new_chat_message.connect(_on_chat_message)
	chat_line_edit.text_submitted.connect(_on_send_message)
	
	
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_chat"):
		self.visible = not self.visible
		if self.visible:
			_on_open()
		else:
			_on_close()
		
		
func _on_open() -> void:
	chat_line_edit.grab_focus()


func _on_close() -> void:
	chat_line_edit.release_focus()
	
	
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
