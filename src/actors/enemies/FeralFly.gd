extends CharacterBody2D
class_name FeralFly

@export var patrol_distance: float = 160.0
@export var move_speed: float = 120.0
@export var damage: int = 1
@export var max_health: int = 2

@onready var start_position: Vector2 = global_position
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $DamageArea

var _direction: int = 1
var _health: int

func _ready() -> void:
    hitbox.body_entered.connect(_on_damage_area_body_entered)
    _health = max_health

func _physics_process(delta: float) -> void:
    velocity.x = _direction * move_speed
    move_and_slide()
    _update_direction()
    _update_animation()

func _update_direction() -> void:
    var offset := global_position.x - start_position.x
    if offset > patrol_distance:
        _direction = -1
    elif offset < -patrol_distance:
        _direction = 1
    sprite.flip_h = _direction < 0

func _update_animation() -> void:
    if not sprite.is_playing():
        sprite.play("fly")

func deal_damage() -> int:
    return damage

func apply_hit(amount: int, direction: int) -> void:
    _health -= amount
    sprite.modulate = Color(1, 0.8, 0.8)
    await get_tree().create_timer(0.05).timeout
    sprite.modulate = Color.WHITE
    if _health <= 0:
        queue_free()

func _on_damage_area_body_entered(body: Node) -> void:
    if body is Player:
        body.apply_knockback(global_position)
        GameState.damage_player(damage)
