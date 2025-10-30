extends CharacterBody2D
class_name Player

@export var move_speed: float = 220.0
@export var jump_force: float = 430.0
@export var gravity: float = 1400.0
@export var max_fall_speed: float = 900.0
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.18
@export var dash_speed: float = 520.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 0.35
@export var attack_damage: int = 1

@onready var animations: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer
@onready var dash_timer: Timer = $DashTimer
@onready var dash_cooldown_timer: Timer = $DashCooldownTimer
@onready var hurtbox: Area2D = $Hurtbox
@onready var attack_area: Area2D = $AttackArea

var _velocity: Vector2 = Vector2.ZERO
var _facing: int = 1
var _double_jump_available: bool = true
var _is_dashing: bool = false
var _attack_locked: bool = false

func _ready() -> void:
    hurtbox.area_entered.connect(_on_hurtbox_area_entered)
    attack_area.monitoring = false
    attack_area.body_entered.connect(_on_attack_area_body_entered)
    GameState.ability_unlocked.connect(_on_ability_unlocked)
    _double_jump_available = GameState.has_ability("double_jump")

func _physics_process(delta: float) -> void:
    if _is_dashing:
        _apply_dash_physics()
    else:
        _apply_gravity(delta)
        _handle_horizontal_input()
        _handle_jump()
    _apply_velocity(delta)
    _update_animation()

func _apply_gravity(delta: float) -> void:
    if not is_on_floor():
        _velocity.y = min(_velocity.y + gravity * delta, max_fall_speed)
    else:
        _velocity.y = max(_velocity.y, 0.0)
        _double_jump_available = GameState.has_ability("double_jump")
        if not coyote_timer.is_stopped():
            coyote_timer.stop()

func _handle_horizontal_input() -> void:
    var direction := Input.get_axis("move_left", "move_right")
    if not _is_dashing:
        _velocity.x = move_speed * direction
    if direction != 0:
        _facing = sign(direction)
        $Visuals.scale.x = _facing
    attack_area.position.x = 18 * _facing

func _handle_jump() -> void:
    if Input.is_action_just_pressed("jump"):
        jump_buffer_timer.start(jump_buffer_time)
    if is_on_floor():
        coyote_timer.start(coyote_time)
    var can_jump := is_on_floor() or not coyote_timer.is_stopped()
    if jump_buffer_timer.time_left > 0.0 and can_jump:
        _do_jump()
    elif jump_buffer_timer.time_left > 0.0 and _double_jump_available:
        _do_jump(true)

func _do_jump(is_double: bool=false) -> void:
    _velocity.y = -jump_force
    jump_buffer_timer.stop()
    coyote_timer.stop()
    if is_double:
        _double_jump_available = false
        animations.play("double_jump")
    else:
        animations.play("jump")

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("dash"):
        _try_dash()
    elif event.is_action_pressed("attack"):
        _try_attack()

func _try_dash() -> void:
    if _is_dashing or dash_cooldown_timer.time_left > 0.0:
        return
    if not GameState.has_ability("dash"):
        return
    _is_dashing = true
    dash_timer.start(dash_duration)
    dash_cooldown_timer.start(dash_cooldown)
    _velocity = Vector2(dash_speed * _facing, 0.0)
    animations.play("dash")

func _apply_dash_physics() -> void:
    if dash_timer.time_left <= 0.0:
        _is_dashing = false

func _try_attack() -> void:
    if _attack_locked:
        return
    _attack_locked = true
    animations.play("attack")
    attack_area.monitoring = true
    await animations.animation_finished
    attack_area.monitoring = false
    _attack_locked = false

func _on_attack_area_body_entered(body: Node) -> void:
    if body.has_method("apply_hit"):
        body.apply_hit(attack_damage, _facing)

func _apply_velocity(delta: float) -> void:
    velocity = _velocity
    move_and_slide()
    _velocity = velocity

func _update_animation() -> void:
    if _is_dashing:
        return
    if not is_on_floor():
        if velocity.y < 0.0:
            animations.play("jump")
        else:
            animations.play("fall")
    elif abs(velocity.x) > 5.0:
        animations.play("run")
    else:
        animations.play("idle")

func _on_hurtbox_area_entered(area: Area2D) -> void:
    var owner := area.get_parent()
    if area.has_method("deal_damage"):
        GameState.damage_player(area.deal_damage())
        apply_knockback(area.global_position)
    elif owner and owner.has_method("deal_damage"):
        GameState.damage_player(owner.deal_damage())
        apply_knockback(owner.global_position)

func apply_knockback(position: Vector2) -> void:
    var direction := (global_position - position).normalized()
    _velocity = direction * Vector2(220, 160)

func _on_ability_unlocked(ability_name: String) -> void:
    if ability_name == "dash":
        dash_cooldown_timer.one_shot = true
    elif ability_name == "double_jump":
        _double_jump_available = true

func respawn(position: Vector2) -> void:
    global_position = position
    _velocity = Vector2.ZERO
    GameState.player_health = GameState.max_health
    _double_jump_available = GameState.has_ability("double_jump")
