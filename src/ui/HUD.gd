extends CanvasLayer

@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthLabel
@onready var geo_label: Label = $MarginContainer/VBoxContainer/GeoLabel

func _ready() -> void:
    GameState.stats_changed.connect(_update_values)
    _update_values()

func _update_values() -> void:
    var filled := "❤".repeat(GameState.player_health)
    var empty := "♡".repeat(max(GameState.max_health - GameState.player_health, 0))
    health_label.text = "Salud: %s%s" % [filled, empty]
    geo_label.text = "Geo: %d" % GameState.geo
