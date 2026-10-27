extends Area3D
class_name PlayerRocket

@export var speed: float = 28.0
@export var direct_damage: float = 120.0
@export var blast_damage: float = 90.0
@export var blast_radius: float = 5.5
@export var blast_impulse: float = 24.0

var direction: Vector3 = Vector3.FORWARD

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(5.0).timeout.connect(queue_free)

func setup(start_pos: Vector3, dir: Vector3) -> void:
	global_position = start_pos
	direction = dir.normalized()
	look_at(global_position + direction, Vector3.UP)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		return
	_explode()

func _explode() -> void:
	SoundFX.play_sound("explosion", 3.0)
	ComicPopup.spawn(get_parent(), global_position + Vector3(0, 0.8, 0), "BOOM", 1.4)
	
	# Alan hasarı ve fiziksel patlama itişi
	var space_state = get_world_3d().direct_space_state
	var enemies = get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if e is Node3D and is_instance_valid(e) and e.get("is_dead") != true:
			var dist = global_position.distance_to(e.global_position)
			if dist <= blast_radius:
				var falloff = 1.0 - (dist / blast_radius)
				var push_dir = (e.global_position - global_position).normalized()
				var knockback = (push_dir + Vector3(0, 0.4, 0)) * (blast_impulse * falloff)
				if e.has_method("take_damage"):
					e.take_damage(blast_damage * falloff, knockback, global_position)

	# Oyuncuya yakınsa ekran sarsıntısı ver
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if p is Player and is_instance_valid(p):
			var p_dist = global_position.distance_to(p.global_position)
			if p_dist <= 12.0:
				p.add_trauma(0.7 * (1.0 - p_dist / 12.0))

	# Görsel flaş ve yok olma
	queue_free()
