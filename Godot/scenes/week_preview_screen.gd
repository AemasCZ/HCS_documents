extends Control

# UI (podle tvé struktury: WeekPreviewScreen/CenterContainer/VBoxContainer/*)
@onready var week_season_label: Label = $CenterContainer/VBoxContainer/WeekSeasonLabel
@onready var team_label: Label = $CenterContainer/VBoxContainer/TeamLabel
@onready var matches_label: RichTextLabel = $CenterContainer/VBoxContainer/MatchesLabel
@onready var simulate_button: Button = $CenterContainer/VBoxContainer/SimulateButton
@onready var log_label: RichTextLabel = $CenterContainer/VBoxContainer/LogLabel

const TEAM_PLAYER := "Team Blue"
const TEAM_OPP := "Team Red"

# Lokální cache (ale reálně persistujeme do GameManageru)
var _total_matches: int = 0
var _played_matches: int = 0

# Dočasný stav v GameManageru (persist mezi scénami)
const _WP_TOTAL_KEY := "week_preview_total_matches"
const _WP_PLAYED_KEY := "week_preview_played_matches"
const _WP_WEEK_ID_KEY := "week_preview_week_id"

func _ready() -> void:
	simulate_button.pressed.connect(_on_simulate_pressed)

	if GameManager.player_data == null:
		_render_error("player_data is null (WeekPreview).")
		return

	_ensure_persistent_state()
	_refresh_ui()
	_log("WeekPreview ready. %d/%d played." % [_played_matches, _total_matches])

# ---------------------------------------------------------------------
# Persistent state helpers
# ---------------------------------------------------------------------

func _get_week_id() -> String:
	var p: PlayerData = GameManager.player_data
	if p == null:
		return ""
	return "%d:%d:%d" % [p.current_season, p.current_month, p.current_week]

func _gm_has(key: String) -> bool:
	return key in GameManager

func _gm_get_int(key: String, default_val: int) -> int:
	if _gm_has(key):
		return int(GameManager.get(key))
	return default_val

func _gm_set(key: String, value) -> void:
	# Godot 4: dynamické property na Object přes set()
	GameManager.set(key, value)

func _ensure_persistent_state() -> void:
	var week_id := _get_week_id()

	# Nový týden / žádný stav -> vygeneruj zápasy
	if (not _gm_has(_WP_WEEK_ID_KEY)) or (str(GameManager.get(_WP_WEEK_ID_KEY)) != week_id):
		_gm_set(_WP_WEEK_ID_KEY, week_id)
		_gm_set(_WP_TOTAL_KEY, randi_range(1, 3))
		_gm_set(_WP_PLAYED_KEY, 0)

	_total_matches = maxi(_gm_get_int(_WP_TOTAL_KEY, 1), 1)
	_played_matches = clampi(_gm_get_int(_WP_PLAYED_KEY, 0), 0, _total_matches)

func _save_persistent_state() -> void:
	_gm_set(_WP_TOTAL_KEY, _total_matches)
	_gm_set(_WP_PLAYED_KEY, _played_matches)

func _clear_persistent_state() -> void:
	# Reset pro další týden (nechceme aby se stav přenesl)
	_gm_set(_WP_WEEK_ID_KEY, "")
	_gm_set(_WP_TOTAL_KEY, 0)
	_gm_set(_WP_PLAYED_KEY, 0)

# ---------------------------------------------------------------------
# UI render
# ---------------------------------------------------------------------

func _refresh_ui() -> void:
	var p: PlayerData = GameManager.player_data
	if p == null:
		_render_error("player_data is null (WeekPreview).")
		return

	week_season_label.text = "Week: %d | Month: %d | Season: %d" % [p.current_week, p.current_month, p.current_season]
	team_label.text = "Team: %s" % TEAM_PLAYER

	_render_matches_list()
	_refresh_button()

func _render_matches_list() -> void:
	matches_label.clear()
	matches_label.append_text("[b]Zápasy tento týden:[/b]\n")

	for i in range(_total_matches):
		var idx := i + 1
		var status := "ODEHRÁNO" if i < _played_matches else "ČEKÁ"
		matches_label.append_text("Zápas #%d: %s vs %s — %s\n" % [idx, TEAM_PLAYER, TEAM_OPP, status])

	matches_label.append_text("\nPostup: %d/%d odehráno\n" % [_played_matches, _total_matches])

func _refresh_button() -> void:
	if _played_matches < _total_matches:
		simulate_button.disabled = false
		simulate_button.text = "Simulovat zápas (%d zbývá)" % (_total_matches - _played_matches)
	else:
		simulate_button.disabled = false
		simulate_button.text = "Pokračovat (trénink + další týden)"

func _render_error(msg: String) -> void:
	week_season_label.text = "ERROR"
	team_label.text = ""
	matches_label.clear()
	matches_label.append_text("ERROR: %s\n" % msg)
	simulate_button.disabled = true
	_log("ERROR: " + msg)

func _log(text: String) -> void:
	log_label.append_text(text + "\n")

# ---------------------------------------------------------------------
# Actions
# ---------------------------------------------------------------------

func _on_simulate_pressed() -> void:
	if GameManager.player_data == null:
		_log("ERROR: player_data is null.")
		return

	# ještě jsou zápasy -> otevřít MatchSim
	if _played_matches < _total_matches:
		# předání shooting do GameManageru (MatchSim si ho vezme)
		var shooting := _get_shooting_skill()
		GameManager.set("match_sim_shooting_skill", shooting)

		# označit zápas jako odehraný hned (aby po návratu už byl "ODEHRÁNO")
		_played_matches += 1
		_save_persistent_state()
		_refresh_ui()

		# ZMĚNA: NEvolat GameManager.goto_match_sim_screen() (u tebe chce argument)
		get_tree().change_scene_to_file("res://scenes/match_sim_screen.tscn")
		return

	# dohrány všechny zápasy -> trénink + advance + návrat na WeekScreen
	_apply_training_and_advance()

func _get_shooting_skill() -> int:
	var p: PlayerData = GameManager.player_data
	if p == null:
		return 1
	return clampi(int(p.get_attr_value(PlayerData.ATTR_SHOOTING)), 1, 99)

func _apply_training_and_advance() -> void:
	var p: PlayerData = GameManager.player_data
	if p == null:
		_log("ERROR: player_data is null (apply_training).")
		return

	# 1) trénink: projet 4 sloty a přidat 1xp
	if p.training_plan == null:
		_log("WARNING: training_plan is null.")
	else:
		for key in p.training_plan:
			p.add_xp_and_resolve(String(key), 1)

	# 2) advance týden
	p.advance_week()

	# 3) vyčistit week preview stav (ať další týden generuje nové zápasy)
	_clear_persistent_state()

	# 4) zpět na WeekScreen
	if GameManager.has_method("goto_week_screen"):
		GameManager.goto_week_screen()
	else:
		get_tree().change_scene_to_file("res://scenes/week_screen.tscn")
