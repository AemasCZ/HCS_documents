extends Resource
class_name PlayerData

# --- Basic identity ---
@export var player_name: String = ""
@export var player_class: String = ""
# ZMĚNA: League & team identity (MVP)
@export var team_name: String = ""
@export var team_overall: int = 0
@export var league_name: String = ""

# --- Time progression (used by WeekScreen) ---
@export var current_week: int = 1
@export var current_month: int = 1
@export var current_season: int = 1

const WEEKS_PER_SEASON: int = 26
const WEEKS_PER_MONTH: int = 4
const MONTHS_PER_SEASON: int = 6

# --- Attributes (MVP) ---
const ATTRIBUTE_MIN: int = 1
const ATTRIBUTE_MAX: int = 99
const BASE_ATTR_VALUE: int = 25

# MVP: kolik XP je potřeba na +1 atribut (zadání = 3)
const XP_PER_LEVEL: int = 3

# Group labels (pro UI)
const GROUP_TECH := "TECH"
const GROUP_MENTAL := "MENTAL"
const GROUP_PHYS := "PHYS"

# --- Attribute keys ---
const ATTR_SHOOTING := "shooting"
const ATTR_PASSING := "passing"
const ATTR_PUCK_CONTROL := "puck_control"
const ATTR_FIRST_TOUCH := "first_touch"
const ATTR_DEFENCE := "defence"

const ATTR_POSITIONING := "positioning"
const ATTR_LEADERSHIP := "leadership"
const ATTR_DISCIPLINE := "discipline"
const ATTR_ANTICIPATION := "anticipation"
const ATTR_CREATIVITY := "creativity"

const ATTR_SPEED := "speed"
const ATTR_ACCELERATION := "acceleration"
const ATTR_STRENGTH := "strength"
const ATTR_AGILITY := "agility"
const ATTR_STAMINA := "stamina"

# --- Useful lists ---
const ALL_ATTRS: Array[String] = [
	ATTR_SHOOTING, ATTR_PASSING, ATTR_PUCK_CONTROL, ATTR_FIRST_TOUCH, ATTR_DEFENCE,
	ATTR_POSITIONING, ATTR_LEADERSHIP, ATTR_DISCIPLINE, ATTR_ANTICIPATION, ATTR_CREATIVITY,
	ATTR_SPEED, ATTR_ACCELERATION, ATTR_STRENGTH, ATTR_AGILITY, ATTR_STAMINA
]

# MVP: TECH atributy, které se dají trénovat (bez mental a bez phys podle zadání)
const TECH_ATTRS: Array[String] = [
	ATTR_SHOOTING,
	ATTR_PASSING,
	ATTR_PUCK_CONTROL,
	ATTR_FIRST_TOUCH,
	ATTR_DEFENCE
]

# Pokud budeš chtít později trénovat i PHYS, nechávám tu i trainable set pro budoucno
const TRAINABLE_ATTRS: Array[String] = [
	ATTR_SHOOTING, ATTR_PASSING, ATTR_PUCK_CONTROL, ATTR_FIRST_TOUCH, ATTR_DEFENCE,
	ATTR_SPEED, ATTR_ACCELERATION, ATTR_STRENGTH, ATTR_AGILITY, ATTR_STAMINA
]

const ATTR_GROUP: Dictionary = {
	ATTR_SHOOTING: GROUP_TECH,
	ATTR_PASSING: GROUP_TECH,
	ATTR_PUCK_CONTROL: GROUP_TECH,
	ATTR_FIRST_TOUCH: GROUP_TECH,
	ATTR_DEFENCE: GROUP_TECH,

	ATTR_POSITIONING: GROUP_MENTAL,
	ATTR_LEADERSHIP: GROUP_MENTAL,
	ATTR_DISCIPLINE: GROUP_MENTAL,
	ATTR_ANTICIPATION: GROUP_MENTAL,
	ATTR_CREATIVITY: GROUP_MENTAL,

	ATTR_SPEED: GROUP_PHYS,
	ATTR_ACCELERATION: GROUP_PHYS,
	ATTR_STRENGTH: GROUP_PHYS,
	ATTR_AGILITY: GROUP_PHYS,
	ATTR_STAMINA: GROUP_PHYS,
}

# ------------------------------------------------------------
#  PLAYER DATA — Konstanty a runtime data
#  (stringy u class musí odpovídat CharacterCreation)
# ------------------------------------------------------------

# --- Classes (stringy odpovídají CharacterCreation) ---
const CLASS_SNIPER: String = "Sniper"
const CLASS_PLAYMAKER: String = "Playmaker"
const CLASS_TWO_WAY: String = "Two-Way Forward"
const CLASS_DEFENSIVE: String = "Defensive Forward"

# Seznam class pro UI (např. OptionButton) a validaci
const CLASS_LIST: Array[String] = [
	CLASS_SNIPER,
	CLASS_PLAYMAKER,
	CLASS_TWO_WAY,
	CLASS_DEFENSIVE
]

# --- League & Teams ---
# Název ligy (zatím pevně daný)
const LEAGUE_NAME: String = "Czech League"

# Slovník: název týmu -> overall rating
const TEAMS: Dictionary = {
	"HC Pardubice": 76,
	"HC Karlovy Vary": 75,
	"HC Plzeň": 75,
	"HC Liberec": 75,
	"HC Třinec": 74,
	"Mountfield HK": 74,
	"HC Sparta Praha": 73,
	"HC Kometa Brno": 73,
	"HC Vítkovice": 72,
	"HC České Budějovice": 72,
	"HC Olomouc": 71,
	"HC Kladno": 71,
	"HC Mladá Boleslav": 71,
	"HC Litvínov": 68
}

# Seřazený seznam názvů týmů (pro UI — OptionButton)
const TEAM_NAMES: Array[String] = [
	"HC Pardubice",
	"HC Karlovy Vary",
	"HC Plzeň",
	"HC Liberec",
	"HC Třinec",
	"Mountfield HK",
	"HC Sparta Praha",
	"HC Kometa Brno",
	"HC Vítkovice",
	"HC České Budějovice",
	"HC Olomouc",
	"HC Kladno",
	"HC Mladá Boleslav",
	"HC Litvínov"
]

# TEST: základní hodnota atributů podle classy (ověření výběru)
# key:String (class) -> int (base hodnota)
const CLASS_BASE_VALUES: Dictionary = {
	CLASS_SNIPER: 10,
	CLASS_PLAYMAKER: 11,
	CLASS_TWO_WAY: 12,
	CLASS_DEFENSIVE: 13
}

# --- Runtime data ---
# Hodnoty atributů hráče
# key:String -> int
var attr_values: Dictionary = {}

# XP do atributů hráče
# key:String -> int
var attr_xp: Dictionary = {}

# ZMĚNA: tréninkový plán (4 sloty TECH; drží celou sezónu/dokud ho nezměníš)
var training_plan: Array[String] = []

# --- Setup ---
func setup(p_name: String, p_class: String, p_team: String = "", p_league: String = "") -> void:
	player_name = p_name.strip_edges()
	player_class = p_class

	current_week = 1
	current_month = 1
	current_season = 1

	_initialize_attributes()
	_apply_class_baseline(player_class)
	_initialize_training_plan()

	# ZMĚNA: uložit tým + ligu a spočítat overall
	team_name = p_team
	league_name = p_league
	if TEAMS.has(p_team):
		team_overall = int(TEAMS[p_team])
	else:
		team_overall = 0

func _initialize_attributes() -> void:
	attr_values.clear()
	attr_xp.clear()

	for key in ALL_ATTRS:
		attr_values[key] = BASE_ATTR_VALUE
		attr_xp[key] = 0

# Nastaví všechny atributy na stejnou hodnotu podle classy (TEST)
func _apply_class_baseline(p_class: String) -> void:
	var base_value: int = BASE_ATTR_VALUE
	if CLASS_BASE_VALUES.has(p_class):
		base_value = int(CLASS_BASE_VALUES[p_class])

	for key in ALL_ATTRS:
		set_attr_value(key, base_value)

# ZMĚNA: výchozí plán (dokud ho hráč nezmění na TrainingScreen)
func _initialize_training_plan() -> void:
	training_plan.clear()
	training_plan.append(ATTR_SHOOTING)
	training_plan.append(ATTR_SHOOTING)
	training_plan.append(ATTR_SHOOTING)
	training_plan.append(ATTR_SHOOTING)

# --- Attribute API ---
func get_attr_value(key: String) -> int:
	return int(attr_values.get(key, BASE_ATTR_VALUE))

func set_attr_value(key: String, value: int) -> void:
	attr_values[key] = clampi(value, ATTRIBUTE_MIN, ATTRIBUTE_MAX)

func get_attr_xp(key: String) -> int:
	return int(attr_xp.get(key, 0))

func set_attr_xp(key: String, value: int) -> void:
	attr_xp[key] = maxi(value, 0)

# Přidá XP a případně provede několik level-upů. Vrací počet level-upů.
func add_xp_and_resolve(key: String, amount: int) -> int:
	if not attr_xp.has(key):
		attr_xp[key] = 0
	if not attr_values.has(key):
		attr_values[key] = BASE_ATTR_VALUE

	attr_xp[key] = maxi(0, int(attr_xp[key]) + amount)

	var level_ups := 0
	while int(attr_xp[key]) >= XP_PER_LEVEL:
		attr_xp[key] = int(attr_xp[key]) - XP_PER_LEVEL

		var current_val := int(attr_values[key])
		if current_val < ATTRIBUTE_MAX:
			attr_values[key] = current_val + 1
			level_ups += 1
		else:
			# Když je stat na capu, XP smažeme (MVP jednoduchost)
			attr_xp[key] = 0
			break

	return level_ups

# --- Time progression ---
func advance_week() -> void:
	current_week += 1

	if current_week > WEEKS_PER_SEASON:
		current_week = 1
		current_season += 1

	# explicitní typ, aby Godot 4.6 bezpečně parsoval
	var month_float: float = floor(((float(current_week) - 1.0) / float(WEEKS_PER_MONTH)) + 1.0)
	current_month = mini(MONTHS_PER_SEASON, int(month_float))

# --- Utility (podle pravidla z MVP) ---
func get_available_trainings(matches_this_week: int) -> int:
	return maxi(4 - matches_this_week, 1)
