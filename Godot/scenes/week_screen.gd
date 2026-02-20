extends Control

@onready var week_label: Label = $CenterContainer/VBoxContainer/WeekLabel
@onready var class_label: Label = $CenterContainer/VBoxContainer/ClassLabel
@onready var matches_label: Label = $CenterContainer/VBoxContainer/MatchesLabel
@onready var trainings_label: Label = $CenterContainer/VBoxContainer/TrainingsLabel

@onready var attributes_label: RichTextLabel = $CenterContainer/VBoxContainer/AttributesLabel

@onready var open_training_button: Button = $CenterContainer/VBoxContainer/OpenTrainingButton
@onready var confirm_week_button: Button = $CenterContainer/VBoxContainer/ConfirmWeekButton

@onready var log_label: RichTextLabel = $CenterContainer/VBoxContainer/LogLabel

var matches_this_week: int = 0
var trainings_available: int = 0
var matches_remaining: int = 0

# Persist stavu v GameManager meta (bez zásahu do GameManager.gd)
const META_MATCHES_WEEK := "ws_matches_week"
const META_MATCHES_SEASON := "ws_matches_season"
const META_MATCHES_TOTAL := "ws_matches_total"
const META_MATCHES_REMAINING := "ws_matches_remaining"
const META_RETURNED_FROM_MATCH := "ws_returned_from_match"
const META_MATCH_SIM_SHOOTING := "match_sim_shooting_skill"

func _ready() -> void:
	open_training_button.pressed.connect(_on_open_training_pressed)
	confirm_week_button.pressed.connect(_on_confirm_week_pressed)

	_ensure_week_state()
	_apply_return_from_match_if_needed()

	_refresh_ui()
	_log("Week screen loaded.")

func _ensure_week_state() -> void:
	if GameManager.player_data == null:
		return

	var p: PlayerData = GameManager.player_data

	var saved_week := int(GameManager.get_meta(META_MATCHES_WEEK, -1))
	var saved_season := int(GameManager.get_meta(META_MATCHES_SEASON, -1))
	var saved_total := int(GameManager.get_meta(META_MATCHES_TOTAL, 0))
	var saved_remaining := int(GameManager.get_meta(META_MATCHES_REMAINING, 0))

	# Nový týden/sezóna nebo prázdné hodnoty -> vygeneruj nový
	var need_new := (saved_week != int(p.current_week)) \
		or (saved_season != int(p.current_season)) \
		or (saved_total <= 0)

	if need_new:
		matches_this_week = randi_range(1, 3) # 1–3
		matches_remaining = matches_this_week

		GameManager.set_meta(META_MATCHES_WEEK, int(p.current_week))
		GameManager.set_meta(META_MATCHES_SEASON, int(p.current_season))
		GameManager.set_meta(META_MATCHES_TOTAL, matches_this_week)
		GameManager.set_meta(META_MATCHES_REMAINING, matches_remaining)
	else:
		matches_this_week = saved_total
		# Remaining může být 0 (když jsou zápasy hotové) -> to JE validní stav, NEgeneruj nový
		matches_remaining = clampi(saved_remaining, 0, saved_total)

	trainings_available = clampi(4 - matches_this_week, 0, 4)

func _apply_return_from_match_if_needed() -> void:
	var returned := bool(GameManager.get_meta(META_RETURNED_FROM_MATCH, false))
	if not returned:
		return

	GameManager.set_meta(META_RETURNED_FROM_MATCH, false)

	# odečti 1 zápas
	matches_remaining = maxi(matches_remaining - 1, 0)
	GameManager.set_meta(META_MATCHES_REMAINING, matches_remaining)

	_log("Returned from MatchSim. Remaining matches: %d/%d" % [matches_remaining, matches_this_week])

	# ZMĚNA: už automaticky nespouštíme trénink
	if matches_remaining <= 0:
		_log("All matches done. Click Train to finish the week.")

func _end_week_apply_training_and_advance() -> void:
	if GameManager.player_data == null:
		_log("ERROR: player_data is null (end of week).")
		return

	var p: PlayerData = GameManager.player_data

	if p.training_plan.size() != 4:
		_log("ERROR: training_plan not set (needs 4 slots). Advancing week anyway.")
	else:
		_log("Training: applying plan (+1 XP each slot).")
		for i in range(trainings_available):
			var key: String = str(p.training_plan[i])
			p.add_xp_and_resolve(key, 1)

	p.advance_week()

	# reset uloženého stavu, aby se pro nový týden vygeneroval nový počet zápasů
	GameManager.set_meta(META_MATCHES_WEEK, -1)
	GameManager.set_meta(META_MATCHES_SEASON, -1)
	GameManager.set_meta(META_MATCHES_TOTAL, 0)
	GameManager.set_meta(META_MATCHES_REMAINING, 0)

	_log("Advanced to Week %d | Month %d | Season %d" % [p.current_week, p.current_month, p.current_season])

	_ensure_week_state()

func _generate_new_week() -> void:
	# PONECHÁNO: existuje, ale nepoužívá se jako zdroj stavu
	matches_this_week = randi_range(0, 3)
	trainings_available = maxi(4 - matches_this_week, 1)

func _refresh_ui() -> void:
	if GameManager.player_data == null:
		week_label.text = "No player data!"
		class_label.text = ""
		matches_label.text = "Matches this week: -"
		trainings_label.text = "Trainings available: -"
		attributes_label.clear()
		return

	var p: PlayerData = GameManager.player_data
	week_label.text = "Week: %d | Month: %d | Season: %d" % [p.current_week, p.current_month, p.current_season]
	# ZMĚNA: tým pod jménem a nad pozicí (class)
	class_label.text = "%s\n%s\n%s" % [p.player_name, p.team_name, p.player_class]

	matches_label.text = "Matches remaining: %d/%d" % [matches_remaining, matches_this_week]
	trainings_label.text = "Trainings available: %d (4 - matches, min 1)" % trainings_available

	attributes_label.clear()
	attributes_label.append_text(_build_attributes_text(p))

	# ZMĚNA: confirm button = simulate match / train
	if matches_remaining > 0:
		confirm_week_button.text = "Simulate match"
		confirm_week_button.disabled = false
	else:
		confirm_week_button.text = "Train"
		confirm_week_button.disabled = false

func _build_attributes_text(p: PlayerData) -> String:
	var lines: Array[String] = []

	lines.append("[b]TRAINING PLAN (TECH)[/b]")
	if p.training_plan.size() == 4:
		lines.append("1: %s" % _pretty_name(p.training_plan[0]))
		lines.append("2: %s" % _pretty_name(p.training_plan[1]))
		lines.append("3: %s" % _pretty_name(p.training_plan[2]))
		lines.append("4: %s" % _pretty_name(p.training_plan[3]))
	else:
		lines.append("Plan not set (needs 4 slots).")
	lines.append("")

	lines.append("[b]TECH[/b]")
	lines.append("Shooting: %d (%d/%dxp)" % [
		p.get_attr_value(PlayerData.ATTR_SHOOTING),
		p.get_attr_xp(PlayerData.ATTR_SHOOTING),
		PlayerData.XP_PER_LEVEL
	])
	lines.append("Passing: %d (%d/%dxp)" % [
		p.get_attr_value(PlayerData.ATTR_PASSING),
		p.get_attr_xp(PlayerData.ATTR_PASSING),
		PlayerData.XP_PER_LEVEL
	])
	lines.append("Puck Control: %d (%d/%dxp)" % [
		p.get_attr_value(PlayerData.ATTR_PUCK_CONTROL),
		p.get_attr_xp(PlayerData.ATTR_PUCK_CONTROL),
		PlayerData.XP_PER_LEVEL
	])
	lines.append("First Touch: %d (%d/%dxp)" % [
		p.get_attr_value(PlayerData.ATTR_FIRST_TOUCH),
		p.get_attr_xp(PlayerData.ATTR_FIRST_TOUCH),
		PlayerData.XP_PER_LEVEL
	])
	lines.append("Defence: %d (%d/%dxp)" % [
		p.get_attr_value(PlayerData.ATTR_DEFENCE),
		p.get_attr_xp(PlayerData.ATTR_DEFENCE),
		PlayerData.XP_PER_LEVEL
	])
	lines.append("")

	lines.append("[b]MENTAL[/b]")
	lines.append("Positioning: %d" % p.get_attr_value(PlayerData.ATTR_POSITIONING))
	lines.append("Leadership: %d" % p.get_attr_value(PlayerData.ATTR_LEADERSHIP))
	lines.append("Discipline: %d" % p.get_attr_value(PlayerData.ATTR_DISCIPLINE))
	lines.append("Anticipation: %d" % p.get_attr_value(PlayerData.ATTR_ANTICIPATION))
	lines.append("Creativity: %d" % p.get_attr_value(PlayerData.ATTR_CREATIVITY))
	lines.append("")

	lines.append("[b]PHYS[/b]")
	lines.append("Speed: %d" % p.get_attr_value(PlayerData.ATTR_SPEED))
	lines.append("Acceleration: %d" % p.get_attr_value(PlayerData.ATTR_ACCELERATION))
	lines.append("Strength: %d" % p.get_attr_value(PlayerData.ATTR_STRENGTH))
	lines.append("Agility: %d" % p.get_attr_value(PlayerData.ATTR_AGILITY))
	lines.append("Stamina: %d" % p.get_attr_value(PlayerData.ATTR_STAMINA))

	return "\n".join(lines)

func _on_open_training_pressed() -> void:
	GameManager.goto_training_screen()

func _on_confirm_week_pressed() -> void:
	if GameManager.player_data == null:
		_log("ERROR: player_data is null.")
		return

	_ensure_week_state()

	# ZMĚNA: když nejsou zápasy, klik spustí trénink + posun týdne
	if matches_remaining <= 0:
		_log("Training clicked.")
		_end_week_apply_training_and_advance()
		_refresh_ui()
		return

	# jinak simuluj zápas
	var p: PlayerData = GameManager.player_data
	var shooting_skill := clampi(int(p.get_attr_value(PlayerData.ATTR_SHOOTING)), 1, 99)

	GameManager.set_meta(META_MATCH_SIM_SHOOTING, shooting_skill)

	get_tree().change_scene_to_file("res://scenes/match_sim_screen.tscn")

func _pretty_name(key: String) -> String:
	match key:
		PlayerData.ATTR_SHOOTING: return "Shooting"
		PlayerData.ATTR_PASSING: return "Passing"
		PlayerData.ATTR_PUCK_CONTROL: return "Puck Control"
		PlayerData.ATTR_FIRST_TOUCH: return "First Touch"
		PlayerData.ATTR_DEFENCE: return "Defence"
		_: return key

func _log(text: String) -> void:
	log_label.append_text(text + "\n")
