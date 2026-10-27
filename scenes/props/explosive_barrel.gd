extends StaticBody3D
class_name ExplosiveBarrel

@export var max_health: float = 20.0
@export var explosion_damage: float = 140.0
@export var blast_radius: float = 6.0
@export var blast_impulse: float = 35.0

@onready var sprite: Sprite3D = $Sprite3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

const HIT_PARTICLES = preload("res://scenes/effects/hit_particles.tscn")

var current_health: float
var is_exploded: bool = false
var damage_tween: Tween = null

func _ready() -> void:
	current_health = max_health

func take_damage(amount: float, _knockback: Vector3 = Vector3.ZERO, _hit_point: Vector3 = Vector3.ZERO) -> void:
	if is_exploded:
		return
	
	current_health -= amount
	
	# Darbe sarsıntısı ve parıltı
	if damage_tween and damage_tween.is_valid():
		damage_tween.kill()
	damage_tween = create_tween()
	sprite.modulate = Color(3.0, 1.5, 1.5, 1.0)
	sprite.scale = Vector3(1.15, 0.85, 1.0)
	damage_tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.12)
	damage_tween.parallel().tween_property(sprite, "scale", Vector3.ONE, 0.12)
	
	if current_health <= 0.0:
		_explode()

func _explode() -> void:
	if is_exploded:
		return
	is_exploded = true
	
	# Çarpışmayı anında kapat
	collision_shape.set_deferred("disabled", true)
	sprite.visible = false
	
	SoundFX.play_sound("explosion", 3.0)
	
	# Kağıt patlama parçacıkları ve çizgi roman BOOM çıkartması
	if HIT_PARTICLES:
		var parts = HIT_PARTICLES.instantiate()
		get_parent().add_child(parts)
		parts.activate(global_position)
	ComicPopup.spawn(get_parent(), global_position + Vector3(0, 1.0, 0), "BOOM", 1.4)
	
	# Patlama ışığı flaşı
	var flash_light = OmniLight3D.new()
	flash_light.light_color = Color(1.0, 0.65, 0.25)
	flash_light.light_energy = 5.0
	flash_light.omni_range = blast_radius * 1.5
	get_parent().add_child(flash_light)
	flash_light.global_position = global_position + Vector3(0, 0.5, 0)
	var lt = create_tween()
	lt.tween_property(flash_light, "light_energy", 0.0, 0.2)
	lt.tween_callback(flash_light.queue_free)

	# Yakındaki oyuncuya ekran sarsıntısı ver
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if p is Player and is_instance_valid(p):
			var p_dist = global_position.distance_to(p.global_position)
			if p_dist <= blast_radius * 2.0:
				p.add_trauma(0.8 * (1.0 - p_dist / (blast_radius * 2.0)))
	
	# Alan hasarı ve etrafı zincirleme patlatma
	var space_state = get_world_3d().direct_space_state
	var shape_params = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = blast_radius
	shape_params.shape = sphere
	shape_params.transform = Transform3D(Basis(), global_position)
	shape_params.collision_mask = 7 # Oyuncu (2), Düşmanlar (4), Diğer variller (1 veya 4)
	
	var hits = space_state.intersect_shape(shape_params, 32)
	for hit in hits:
		var collider = hit.collider
		if collider and collider != self:
			var hit_pos = collider.global_position
			var dist = global_position.distance_to(hit_pos)
			var falloff = clamp(1.0 - (dist / blast_radius), 0.25, 1.0)
			var dmg = explosion_damage * falloff
			var push_dir = (hit_pos - global_position).normalized()
			if push_dir == Vector3.ZERO:
				push_dir = Vector3.UP
			var push_vec = (push_dir + Vector3(0, 0.35, 0)).normalized() * blast_impulse * falloff
			
			if collider.has_method("take_damage"):
				collider.take_damage(dmg, push_vec, hit_pos)
	
	# Hafif gecikmeyle yok et
	get_tree().create_timer(0.2).timeout.connect(queue_free)
