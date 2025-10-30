extends Area2D
class_name GeoShard

@export var amount: int = 5
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    if animation_player.has_animation("idle"):
        animation_player.play("idle")

func _on_body_entered(body: Node) -> void:
    if body is Player:
        GameState.add_geo(amount)
        queue_free()
