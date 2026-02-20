extends Control

@onready var name_input: LineEdit = $CenterContainer/VBoxContainer/NameInput
@onready var class_select: OptionButton = $CenterContainer/VBoxContainer/ClassSelect
@onready var team_select: OptionButton = $CenterContainer/VBoxContainer/TeamSelect
@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton

const CLASSES: Array[String] = [
	"Sniper",
	"Playmaker",
	"Two-Way Forward",
	"Defensive Forward"
]

func _ready() -> void:
	_populate_classes()
	_populate_teams()
	start_button.pressed.connect(_on_start_pressed)

func _populate_classes() -> void:
	class_select.clear()
	for c in CLASSES:
		class_select.add_item(c)

# ZMĚNA: musí být samostatná metoda (ne zanořená v _populate_classes)
func _populate_teams() -> void:
	team_select.clear()
	for t in PlayerData.TEAM_NAMES:
		team_select.add_item(t)

func _on_start_pressed() -> void:
	var player_name := name_input.text.strip_edges()
	if player_name == "":
		player_name = "Player"

	var selected_class := class_select.get_item_text(class_select.selected)
	var selected_team := team_select.get_item_text(team_select.selected)

	# ZMĚNA: předání týmu do new_game (GameManager musí mít 3. parametr)
	GameManager.new_game(player_name, selected_class, selected_team)
	GameManager.goto_week_screen()
