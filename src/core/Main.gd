extends Node2D

@export var start_room: PackedScene
@export var player_scene: PackedScene
@export var hud_scene: PackedScene

var current_room: Node
var player: Player
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
    GameState.reset()
    GameState.stats_changed.connect(_on_stats_changed)
    _spawn_room()
    _spawn_player()
    _spawn_hud()
    camera.make_current()
    _on_stats_changed()

func _physics_process(delta: float) -> void:
    if player:
        var target := player.global_position
        camera.global_position = camera.global_position.lerp(target, clamp(delta * 5.0, 0, 1))

func _spawn_room() -> void:
    if current_room:
        current_room.queue_free()
    current_room = start_room.instantiate()
    add_child(current_room)

func _spawn_player() -> void:
    player = player_scene.instantiate()
    add_child(player)
    player.global_position = _find_spawn_point()
    GameState.respawn_position = player.global_position

func _spawn_hud() -> void:
    var hud := hud_scene.instantiate()
    add_child(hud)

func _find_spawn_point() -> Vector2:
    if not current_room:
        return Vector2.ZERO
    for child in current_room.get_children():
        if child is Marker2D and child.name == "SpawnPoint":
            return child.global_position
        if child.has_node("SpawnPoint"):
            var marker := child.get_node("SpawnPoint")
            if marker is Marker2D:
                return marker.global_position
    return current_room.global_position

func _on_stats_changed() -> void:
    if not player:
        return
    if GameState.player_health <= 0:
        _respawn()

func _respawn() -> void:
    player.respawn(GameState.respawn_position)

