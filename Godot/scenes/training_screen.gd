extends Control

@onready var slot1: OptionButton = $CenterContainer/VBoxContainer/SlotsGrid/Slot1Option
@onready var slot2: OptionButton = $CenterContainer/VBoxContainer/SlotsGrid/Slot2Option
@onready var slot3: OptionButton = $CenterContainer/VBoxContainer/SlotsGrid/Slot3Option
@onready var slot4: OptionButton = $CenterContainer/VBoxContainer/SlotsGrid/Slot4Option

@onready var save_button: Button = $CenterContainer/VBoxContainer/ButtonRow/SaveButton
@onready var back_button: Button = $CenterContainer/VBoxContainer/ButtonRow/BackButton

# TECH klíče přímo z PlayerData (v tvém projektu existují)
var _tech_keys: Array[String] = PlayerData.TECH_ATTRS.duplicate()

func _ready() -> void:
	save_button.pressed.connect(_on_save_pressed)
	back_button.pressed.connect(_on_back_pressed)

	if GameManager.player_data == null:
		GameManager.goto_week_screen()
		return

	_fill_option(slot1)
	_fill_option(slot2)
	_fill_option(slot3)
	_fill_option(slot4)

	_load_from_player_data()

func _fill_option(ob: OptionButton) -> void:
	ob.clear()
	for key in _tech_keys:
		ob.add_item(_pretty_name(key))
	ob.select(0)

func _load_from_player_data() -> void:
	var p: PlayerData = GameManager.player_data

	# Čti přímo z p.training_plan
	if p.training_plan is Array and p.training_plan.size() == 4:
		_select_by_key(slot1, str(p.training_plan[0]))
		_select_by_key(slot2, str(p.training_plan[1]))
		_select_by_key(slot3, str(p.training_plan[2]))
		_select_by_key(slot4, str(p.training_plan[3]))
		return

	# fallback default
	_select_by_key(slot1, PlayerData.ATTR_SHOOTING)
	_select_by_key(slot2, PlayerData.ATTR_SHOOTING)
	_select_by_key(slot3, PlayerData.ATTR_SHOOTING)
	_select_by_key(slot4, PlayerData.ATTR_SHOOTING)

func _select_by_key(ob: OptionButton, key: String) -> void:
	var idx := _tech_keys.find(key)
	ob.select(maxi(idx, 0))

func _on_save_pressed() -> void:
	var p: PlayerData = GameManager.player_data
	if p == null:
		return

	var new_plan: Array[String] = [
		_tech_keys[slot1.selected],
		_tech_keys[slot2.selected],
		_tech_keys[slot3.selected],
		_tech_keys[slot4.selected],
	]

	# ULOŽIT do PlayerData.training_plan (to je ten fix)
	p.training_plan = new_plan

	GameManager.goto_week_screen()

func _on_back_pressed() -> void:
	GameManager.goto_week_screen()

func _pretty_name(key: String) -> String:
	match key:
		PlayerData.ATTR_SHOOTING: return "Shooting"
		PlayerData.ATTR_PASSING: return "Passing"
		PlayerData.ATTR_PUCK_CONTROL: return "Puck Control"
		PlayerData.ATTR_FIRST_TOUCH: return "First Touch"
		PlayerData.ATTR_DEFENCE: return "Defence"
		_: return key
