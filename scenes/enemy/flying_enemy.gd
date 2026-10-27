extends CharacterBody3D
class_name FlyingEnemy

# --- Uçuş ve Savaş Parametreleri ---
@export_group("Özellikler")
@export var max_health: float = 40.0
@export var move_speed: float = 5.0
@export var acceleration: float = 8.0
@export var hover_height: float = 4.2      # Oyuncunun üzerindeki irtifa
@export var preferred_distance: float = 11.0 # Korunacak mesafe
@export var shoot_interval: float = 2.2     # Atış aralığı (saniye)

# --- Referanslar & Sahneler ---
@onready var sprite: Sprite3D = $Sprite3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

const FIREBALL_SCENE = preload("res://scenes/projectiles/fireball.tscn")
const HIT_PARTICLES = preload("res://scenes/effects/hit_particles.tscn")
const HEALTH_PICKUP = preload("res://scenes/pickups/health_pickup.tscn")
const ARMOR_PICKUP = preload("res://scenes/pickups/armor_pickup.tscn")
const AMMO_PICKUP = preload("res://scenes/pickups/ammo_pickup.tscn")

var current_health: float
var player: Player = null
var shoot_timer: float = 0.0
var hover_timer: float = 0.0
var is_dead: bool = false
var is_staggered: bool = false
var is_alerted: bool = false
var stagger_timer: float = 0.0
var damage_tween: Tween = null

func _ready() -> void:
	current_health = max_health
	if sprite:
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	shoot_timer = randf_range(1.0, shoot_interval)
	_find_player()

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as Player

func _physics_process(delta: float) -> void:
	if is_dead:
		# Öldüğünde yerçekimiyle düşüş
		velocity.y -= 24.0 * delta
		move_and_slide()
		return

	if not player:
		_find_player()
		move_and_slide()
		return

	hover_timer += delta
	shoot_timer -= delta

	# İstenen hedef pozisyonu hesapla: Oyuncunun üzerinde ve belirli mesafede
	var to_player = player.global_position - global_position
	var flat_to_player = Vector3(to_player.x, 0, to_player.z)
	var current_dist = flat_to_player.length()

	# Uzaktaki uçanlar da yavaşça oyuncunun üzerine doğru süzülür
	var flight_speed_mult = 1.0
	if not is_alerted:
		if current_dist <= 26.0 and _has_line_of_sight():
			is_alerted = true
		else:
			flight_speed_mult = 0.6

	# Oyuncunun irtifası + süzülme dalgası
	var target_y = player.global_position.y + hover_height + sin(hover_timer * 2.5) * 0.4
	var target_vel = Vector3.ZERO

	# İleri / Geri mesafe koruma (Kite)
	if current_dist > preferred_distance + 2.0:
		target_vel += flat_to_player.normalized() * move_speed
	elif current_dist < preferred_distance - 2.0:
		target_vel -= flat_to_player.normalized() * move_speed

	# Yanal hafif salınım (Oyuncuyu kuşatma / strafe)
	var strafe_dir = flat_to_player.normalized().cross(Vector3.UP)
	target_vel += strafe_dir * sin(hover_timer * 1.5) * (move_speed * 0.7)

	# Yükseklik takibi
	var y_diff = target_y - global_position.y
	target_vel.y = clamp(y_diff * 3.0, -move_speed, move_speed)

	target_vel *= flight_speed_mult

	velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta)
	velocity.y = move_toward(velocity.y, target_vel.y, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta)

	move_and_slide()

	# Görsel süzülme açısı
	if sprite:
		sprite.rotation.z = sin(hover_timer * 2.0) * deg_to_rad(6.0)

	# Sersemleme (Stagger / Downed) - Yere inip infaz bekleme
	if is_staggered:
		stagger_timer += delta * 15.0
		var pulse = (sin(stagger_timer) + 1.0) * 0.5
		sprite.modulate = Color.WHITE.lerp(Color(3.0, 1.4, 0.2, 1.0), pulse)
		velocity = velocity.move_toward(Vector3.ZERO, 15.0 * delta)
		move_and_slide()
		return

	if shoot_timer <= 0.0 and current_dist < 25.0:
		_shoot_fireball()
		shoot_timer = shoot_interval


func _shoot_fireball() -> void:
	if not FIREBALL_SCENE or not player:
		return

	# Ön hazırlık parlaması
	var prep_tween = create_tween()
	sprite.modulate = Color(2.5, 1.2, 0.4, 1.0)
	prep_tween.tween_property(sprite, "modulate", Color.WHITE, 0.25)

	var fireball = FIREBALL_SCENE.instantiate()
	get_parent().add_child(fireball)
	var shoot_origin = global_position + Vector3(0, 0.2, 0)
	var target_pos = player.global_position + Vector3(0, 1.0, 0) # Oyuncunun gövdesi
	if fireball.has_method("setup"):
		fireball.setup(shoot_origin, target_pos)

func _has_line_of_sight() -> bool:
	if not player:
		return false
	var space_state = get_world_3d().direct_space_state
	var from = global_position
	var to = player.global_position + Vector3(0, 1.2, 0)
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1 # Duvarlar
	var result = space_state.intersect_ray(query)
	return result.is_empty()

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO, hit_point: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return

	is_alerted = true
	current_health -= amount
	velocity += knockback * 0.7 # Havada savrulma

	# Kan / Kağıt Parçacığı
	if HIT_PARTICLES:
		var p = HIT_PARTICLES.instantiate()
		get_parent().add_child(p)
		var spawn_pos = hit_point if hit_point != Vector3.ZERO else global_position
		p.activate(spawn_pos, knockback)

	# Darbe parıltısı ve yamulması
	if damage_tween and damage_tween.is_valid():
		damage_tween.kill()
	damage_tween = create_tween()
	sprite.modulate = Color(3.5, 3.5, 3.5, 1.0)
	sprite.scale = Vector3(1.3, 0.7, 1.0)
	damage_tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.14)
	damage_tween.parallel().tween_property(sprite, "scale", Vector3.ONE, 0.14)

	if current_health <= 0.0:
		if not is_staggered:
			_enter_downed_state(knockback)
		else:
			_die(knockback, false)

func _enter_downed_state(knockback: Vector3) -> void:
	is_staggered = true
	current_health = 0.0
	stagger_timer = 0.0
	velocity = knockback * 0.4
	
	# Havadan zemine doğru düşüş
	var drop_tween = create_tween()
	drop_tween.tween_property(self, "global_position:y", 0.35, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if sprite:
		drop_tween.parallel().tween_property(sprite, "rotation:z", deg_to_rad(65.0), 0.3)

	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(func():
		if is_instance_valid(self) and not is_dead:
			_die(Vector3.UP * 2.0, false)
	)

func execute() -> void:
	if is_dead:
		return
	_die(Vector3.UP * 4.0, true)

func _die(death_impulse: Vector3 = Vector3.ZERO, is_finisher: bool = false) -> void:
	is_dead = true
	is_staggered = false

	set_collision_layer_value(3, false)
	set_collision_mask_value(1, false)
	set_collision_mask_value(2, false)
	if collision_shape:
		collision_shape.disabled = true


	_spawn_loot(is_finisher)

	if HIT_PARTICLES:
		var p = HIT_PARTICLES.instantiate()
		get_parent().add_child(p)
		p.amount = 55 if is_finisher else 40
		p.activate(global_position, death_impulse)

	if is_finisher:
		_spawn_split_halves(death_impulse)
	else:
		# Havada sönerek yere düşüş
		velocity = death_impulse * 1.5 + Vector3(0, 4.0, 0)
		var death_tween = create_tween()
		death_tween.parallel().tween_property(sprite, "scale", Vector3(0.1, 0.1, 0.1), 0.6)
		death_tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.6)
		death_tween.tween_callback(queue_free)

func _spawn_split_halves(death_impulse: Vector3) -> void:
	if not sprite or not sprite.texture:
		queue_free()
		return
	
	sprite.visible = false
	var tex = sprite.texture
	var tex_w = tex.get_width()
	var tex_h = tex.get_height()
	var half_w = float(tex_w) / 2.0
	
	var cam = get_viewport().get_camera_3d() if get_viewport() else null
	var cam_right = cam.global_transform.basis.x.normalized() if cam else Vector3.RIGHT
	cam_right.y = 0.0
	cam_right = cam_right.normalized()

	var half_pixel_offset = (half_w * 0.5) * sprite.pixel_size * sprite.scale.x
	var center_pos = sprite.global_position

	var left_half = Sprite3D.new()
	left_half.texture = tex
	left_half.region_enabled = true
	left_half.region_rect = Rect2(0, 0, half_w, tex_h)
	left_half.pixel_size = sprite.pixel_size
	left_half.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	left_half.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	left_half.scale = sprite.scale
	left_half.global_position = center_pos - cam_right * half_pixel_offset
	get_parent().add_child(left_half)
	
	var right_half = Sprite3D.new()
	right_half.texture = tex
	right_half.region_enabled = true
	right_half.region_rect = Rect2(half_w, 0, half_w, tex_h)
	right_half.pixel_size = sprite.pixel_size
	right_half.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	right_half.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	right_half.scale = sprite.scale
	right_half.global_position = center_pos + cam_right * half_pixel_offset
	get_parent().add_child(right_half)

	if HIT_PARTICLES:
		var p = HIT_PARTICLES.instantiate()
		get_parent().add_child(p)
		p.amount = 45
		p.activate(center_pos, Vector3.UP * 4.5 + death_impulse * 0.5)

	# 1. Aşama: Yırtılma Gerilimi
	var rip_seq = create_tween()
	var rip_start_left = left_half.global_position - cam_right * 0.35
	var rip_start_right = right_half.global_position + cam_right * 0.35

	rip_seq.parallel().tween_property(left_half, "global_position", rip_start_left, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	rip_seq.parallel().tween_property(left_half, "rotation:z", deg_to_rad(-14.0), 0.08)
	rip_seq.parallel().tween_property(right_half, "global_position", rip_start_right, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	rip_seq.parallel().tween_property(right_half, "rotation:z", deg_to_rad(14.0), 0.08)

	# 2. Aşama: Kağıt gibi süzülerek ayrılma
	var left_final = left_half.global_position - cam_right * 2.2 + Vector3(0, -1.2, 0)
	var right_final = right_half.global_position + cam_right * 2.2 + Vector3(0, -1.2, 0)

	rip_seq.tween_property(left_half, "global_position", left_final, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rip_seq.parallel().tween_property(left_half, "rotation:z", deg_to_rad(-70.0), 0.45)
	rip_seq.parallel().tween_property(left_half, "modulate:a", 0.0, 0.45)

	rip_seq.parallel().tween_property(right_half, "global_position", right_final, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rip_seq.parallel().tween_property(right_half, "rotation:z", deg_to_rad(70.0), 0.45)
	rip_seq.parallel().tween_property(right_half, "modulate:a", 0.0, 0.45)

	rip_seq.tween_callback(func():
		if is_instance_valid(left_half): left_half.queue_free()
		if is_instance_valid(right_half): right_half.queue_free()
		queue_free()
	)

	rip_seq.parallel().tween_property(right_half, "global_position", right_final, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rip_seq.parallel().tween_property(right_half, "rotation:z", deg_to_rad(65.0), 0.55)
	rip_seq.parallel().tween_property(right_half, "modulate:a", 0.0, 0.55)

	rip_seq.tween_callback(func():
		if is_instance_valid(left_half): left_half.queue_free()
		if is_instance_valid(right_half): right_half.queue_free()
		queue_free()
	)



func _spawn_loot(is_guaranteed: bool) -> void:
	if is_guaranteed:
		if HEALTH_PICKUP:
			_drop_pickup(HEALTH_PICKUP)
		if ARMOR_PICKUP:
			_drop_pickup(ARMOR_PICKUP)
		if AMMO_PICKUP:
			_drop_pickup(AMMO_PICKUP)
	else:
		var roll = randf()
		if roll < 0.25 and HEALTH_PICKUP:
			_drop_pickup(HEALTH_PICKUP)
		elif roll < 0.45 and ARMOR_PICKUP:
			_drop_pickup(ARMOR_PICKUP)
		elif roll < 0.70 and AMMO_PICKUP:
			_drop_pickup(AMMO_PICKUP)

func _drop_pickup(scene: PackedScene) -> void:
	var item = scene.instantiate() as Node3D
	item.set("is_static_world_item", false)
	get_parent().add_child(item)
	var offset = Vector3(randf_range(-0.4, 0.4), 0.5, randf_range(-0.4, 0.4))
	item.global_position = global_position + offset

