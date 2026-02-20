extends Node

const PLAYER_DATA_SCRIPT := preload("res://resources/PlayerData.gd")

var player_data = null

const SCENE_CHARACTER_CREATION := "res://scenes/character_creation.tscn"
const SCENE_WEEK_SCREEN := "res://scenes/week_screen.tscn"
const SCENE_TRAINING_SCREEN := "res://scenes/training_screen.tscn"

# ZMĚNA: nové scény
const SCENE_WEEK_PREVIEW_SCREEN := "res://scenes/week_preview_screen.tscn"
const SCENE_MATCH_SIM_SCREEN := "res://scenes/match_sim_screen.tscn"

# ZMĚNA: stav mezi scénami (protože change_scene_to_file reloaduje scénu)
var week_preview_total_matches: int = 0
var week_preview_played_matches: int = 0
var match_sim_shooting_skill: int = 1

func _ready() -> void:
	randomize()

func new_game(player_name: String, player_class: String) -> void:
	player_data = PLAYER_DATA_SCRIPT.new()
	player_data.setup(player_name, player_class)

func change_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)

func goto_character_creation() -> void:
	change_scene(SCENE_CHARACTER_CREATION)

func goto_week_screen() -> void:
	change_scene(SCENE_WEEK_SCREEN)

func goto_training_screen() -> void:
	change_scene(SCENE_TRAINING_SCREEN)

# ZMĚNA: nové goto
func goto_week_preview_screen() -> void:
	change_scene(SCENE_WEEK_PREVIEW_SCREEN)

func goto_match_sim_screen(shooting_skill: int) -> void:
	match_sim_shooting_skill = clampi(shooting_skill, 1, 99)
	change_scene(SCENE_MATCH_SIM_SCREEN)

func reset_week_preview_state() -> void:
	week_preview_total_matches = 0
	week_preview_played_matches = 0
	match_sim_shooting_skill = 1
