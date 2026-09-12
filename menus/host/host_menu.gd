class_name HostMenu
extends GenericPopup


signal lobby_created(lobby_name: String, max_players: int)


@onready var lobby_name_line: LineEdit = %LobbyNameLineEdit
@onready var num_players_slider: Slider = %NumPlayersSlider
@onready var start_button: Button = %StartButton


func _ready() -> void:
	lobby_name_line.text_changed.connect(_on_lobby_name_changed)
	start_button.pressed.connect(_on_start_pressed)
			
			
func _on_lobby_name_changed(text: String) -> void:
	start_button.disabled = text.is_empty()
	
	
func _on_start_pressed() -> void:
	close()
	lobby_created.emit(lobby_name_line.text, num_players_slider.value)
