extends Control

@onready var name_input: LineEdit = $CenterContainer/VBoxContainer/NameInput
@onready var class_select: OptionButton = $CenterContainer/VBoxContainer/ClassSelect
@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton

const CLASSES := [
	"Sniper",
	"Playmaker",
	"Two-Way Forward",
	"Defensive Forward"
]

func _ready() -> void:
	_populate_classes()
	start_button.pressed.connect(_on_start_pressed)

func _populate_classes() -> void:
	class_select.clear()
	for c in CLASSES:
		class_select.add_item(c)

func _on_start_pressed() -> void:
	var player_name := name_input.text.strip_edges()
	
	if player_name == "":
		player_name = "Player"

	var selected_class := class_select.get_item_text(class_select.selected)

	GameManager.new_game(player_name, selected_class)
	GameManager.goto_week_screen()
