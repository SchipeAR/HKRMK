extends Node
class_name GameState

signal stats_changed
signal ability_unlocked(ability_name)

var player_health: int = 5:
    set(value):
        field = clamp(value, 0, max_health)
        emit_signal("stats_changed")

var max_health: int = 5
var geo: int = 0
var respawn_position: Vector2 = Vector2.ZERO
var unlocked_abilities: Dictionary = {
    "double_jump": false,
    "dash": false,
    "wall_slide": false,
}

func _ready() -> void:
    reset()

func reset() -> void:
    player_health = max_health
    geo = 0
    respawn_position = Vector2.ZERO
    for ability in unlocked_abilities.keys():
        unlocked_abilities[ability] = false
    emit_signal("stats_changed")

func damage_player(amount: int) -> void:
    change_health(-abs(amount))

func heal_player(amount: int) -> void:
    change_health(abs(amount))

func change_health(amount: int) -> void:
    player_health = clamp(player_health + amount, 0, max_health)
    emit_signal("stats_changed")

func add_geo(amount: int) -> void:
    geo = max(0, geo + amount)
    emit_signal("stats_changed")

func spend_geo(amount: int) -> bool:
    if geo >= amount:
        geo -= amount
        emit_signal("stats_changed")
        return true
    return false

func unlock_ability(ability_name: String) -> void:
    if ability_name in unlocked_abilities and not unlocked_abilities[ability_name]:
        unlocked_abilities[ability_name] = true
        emit_signal("ability_unlocked", ability_name)

func has_ability(ability_name: String) -> bool:
    return unlocked_abilities.get(ability_name, false)
