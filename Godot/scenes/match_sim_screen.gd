extends Control

@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var score_label: Label = $CenterContainer/VBoxContainer/ScoreLabel
@onready var info_label: Label = $CenterContainer/VBoxContainer/InfoLabel
@onready var chances_label: RichTextLabel = $CenterContainer/VBoxContainer/ChancesLabel
@onready var back_button: Button = $CenterContainer/VBoxContainer/BackButton

const META_MATCH_SIM_SHOOTING := "match_sim_shooting_skill"
const META_RETURNED_FROM_MATCH := "ws_returned_from_match"

var shooting_skill: int = 1

var _blue_goals: int = 0
var _red_goals: int = 1 # soupeř vždy dá 1 gól automaticky

func _ready() -> void:
	# připrav UI
	title_label.text = "Match simulation"
	chances_label.clear()

	back_button.visible = false
	back_button.disabled = true
	back_button.pressed.connect(_on_back_pressed)

	# vstup: shooting skill z WeekScreenu (přes GameManager meta)
	shooting_skill = int(GameManager.get_meta(META_MATCH_SIM_SHOOTING, 1))
	shooting_skill = clampi(shooting_skill, 1, 99)

	_blue_goals = 0
	_red_goals = 1
	_update_score()

	info_label.text = "Opponent scores 1 automatically.\nShooting chance: %d%%" % shooting_skill

	_run_simulation()

func _update_score() -> void:
	score_label.text = "Team Blue %d – %d Team Red" % [_blue_goals, _red_goals]

func _run_simulation() -> void:
	# 5 šancí, postupně, každá po 0.5s
	for i in range(5):
		await get_tree().create_timer(0.5).timeout

		var idx := i + 1
		var is_goal := (randf() * 100.0) < float(shooting_skill)

		if is_goal:
			_blue_goals += 1
			_update_score()
			chances_label.append_text("Šance #%d — GOL\n" % idx)
		else:
			chances_label.append_text("Šance #%d — NIC\n" % idx)

	# po všech šancích
	info_label.text = "Done. Click Back to return."
	back_button.visible = true
	back_button.disabled = false

func _on_back_pressed() -> void:
	# signal WeekScreenu: odehrál se zápas
	GameManager.set_meta(META_RETURNED_FROM_MATCH, true)

	# návrat na WeekScreen
	get_tree().change_scene_to_file("res://scenes/week_screen.tscn")
