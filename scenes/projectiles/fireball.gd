extends Area3D
class_name EnemyProjectile

@export var speed: float = 16.0
@export var damage: float = 15.0
@export var lifetime: float = 6.0

var direction: Vector3 = Vector3.FORWARD

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func setup(start_pos: Vector3, target_pos: Vector3) -> void:
	global_position = start_pos
	direction = (target_pos - start_pos).normalized()
	# Hedefe dön
	look_at(global_position + direction, Vector3.UP)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		body.take_damage(damage, global_position)
		queue_free()
	elif not body.is_in_group("enemy") and body != self:
		# Duvara veya zemine çarptı
		queue_free()
