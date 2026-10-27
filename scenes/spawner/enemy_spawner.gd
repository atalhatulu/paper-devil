extends Node3D
class_name EnemySpawner

@export var enabled: bool = true
@export var spawn_interval: float = 2.8
@export var max_enemies: int = 14
@export var min_spawn_distance: float = 14.0
@export var max_spawn_distance: float = 32.0

var enemy_scenes: Array[PackedScene] = [
	preload("res://scenes/enemy/ground/enemy_ground_00.tscn"),
	preload("res://scenes/enemy/ground/enemy_ground_01.tscn"),
	preload("res://scenes/enemy/ground/enemy_ground_02.tscn"),
	preload("res://scenes/enemy/ground/enemy_ground_03.tscn"),
	preload("res://scenes/enemy/flying/enemy_flying_01.tscn"),
	preload("res://scenes/enemy/flying/enemy_flying_02.tscn")
]

var spawn_timer: float = 0.0
var player: Player = null

func _ready() -> void:
	spawn_timer = spawn_interval

func _physics_process(delta: float) -> void:
	if not enabled:
		return

	if not player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0] as Player
		return

	if player.is_dead:
		return

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = spawn_interval
		_try_spawn_enemy()

func _try_spawn_enemy() -> void:
	var current_enemies = get_tree().get_nodes_in_group("enemy")
	if current_enemies.size() >= max_enemies:
		return

	# Rastgele bir düşman sahnesi seç
	var scene = enemy_scenes.pick_random()
	if not scene:
		return

	var enemy_instance = scene.instantiate() as Node3D
	var spawn_pos = _get_random_spawn_position(enemy_instance is FlyingEnemy)

	get_parent().add_child(enemy_instance)
	enemy_instance.global_position = spawn_pos

func _get_random_spawn_position(is_flying: bool) -> Vector3:
	var angle = randf() * TAU
	var dist = randf_range(min_spawn_distance, max_spawn_distance)
	var offset = Vector3(cos(angle) * dist, 0, sin(angle) * dist)
	
	var base_pos = player.global_position + offset
	# Harita sınırlarında tut (zemin 80x80)
	base_pos.x = clamp(base_pos.x, -36.0, 36.0)
	base_pos.z = clamp(base_pos.z, -36.0, 36.0)

	if is_flying:
		base_pos.y = randf_range(3.5, 6.0)
	else:
		base_pos.y = 0.1

	return base_pos
