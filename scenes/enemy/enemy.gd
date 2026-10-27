extends CharacterBody3D
class_name Enemy

enum WalkStyle {
	WADDLE,   # Sağa-sola paytak salınım (Standart)
	HOP,      # Zıplayarak sıçrayış (Agresif / Hızlı)
	SKITTER,  # Böceksi hızlı titreme (Küçük / Çevik)
	FLOAT     # Hayaletsi havada süzülme (Uçan / Büyücü)
}

# --- Temel Nitelikler ---
@export_group("Özellikler")
@export var walk_style: WalkStyle = WalkStyle.WADDLE
@export var max_health: float = 60.0
@export var move_speed: float = 6.5
@export var acceleration: float = 18.0
@export var stopping_distance: float = 1.2
@export var gravity: float = 24.0

# --- Saldırı Parametreleri ---
@export_group("Saldırı")
@export var attack_damage: float = 14.0
@export var attack_range: float = 1.8
@export var attack_cooldown: float = 1.1

# --- Prosedürel Yürüme Ayarları ---
@export_group("Animasyon Parametreleri")
@export var anim_speed: float = 12.0
@export var tilt_amount: float = 9.0
@export var bounce_amount: float = 0.09

# --- Düğümler & Efektler ---
@onready var sprite: Sprite3D = $Sprite3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

const HIT_PARTICLES = preload("res://scenes/effects/hit_particles.tscn")
const HEALTH_PICKUP = preload("res://scenes/pickups/health_pickup.tscn")
const ARMOR_PICKUP = preload("res://scenes/pickups/armor_pickup.tscn")
const AMMO_PICKUP = preload("res://scenes/pickups/ammo_pickup.tscn")
const CORPSE_TEX = preload("res://assets/Props/paper_corpse.png")

var current_health: float
var player: Node3D = null
var anim_timer: float = 0.0
var attack_timer: float = 0.0
var base_sprite_y: float = 0.96
var base_scale: Vector3 = Vector3.ONE
var sprite_half_height: float = 0.96
var is_dead: bool = false
var is_staggered: bool = false
var is_alerted: bool = false
var stagger_timer: float = 0.0
var friction: float = 35.0
var damage_tween: Tween = null

# Navigasyon ve Performans Optimizasyonları
var nav_agent: NavigationAgent3D = null
var nav_timer: float = 0.0
var cached_sep_dir: Vector3 = Vector3.ZERO
var sep_timer: float = 0.0
var cached_has_los: bool = false
var los_timer: float = 0.0
var wall_slide_bias: float = 0.0
var wall_slide_timer: float = 0.0

func _ready() -> void:
	current_health = max_health
	floor_snap_length = 0.4
	floor_constant_speed = true
	if sprite:
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		base_sprite_y = sprite.position.y
		base_scale = sprite.scale
		sprite_half_height = base_sprite_y
	
	nav_agent = NavigationAgent3D.new()
	nav_agent.path_desired_distance = 0.8
	nav_agent.target_desired_distance = 1.2
	nav_agent.path_max_distance = 4.0
	nav_agent.avoidance_enabled = false
	add_child(nav_agent)
	nav_timer = randf_range(0.0, 0.2)
	sep_timer = randf_range(0.0, 0.25)
	los_timer = randf_range(0.0, 0.2)

	_find_player()

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta: float) -> void:
	if is_dead:
		move_and_slide()
		return

	# Yerçekimi (FLOAT stilinde yerçekimi kapalıdır)
	if walk_style != WalkStyle.FLOAT and not is_on_floor():
		velocity.y -= gravity * delta

	if not player:
		_find_player()
		move_and_slide()
		_process_walk_style(delta, 0.0)
		return

	var diff = player.global_position - global_position
	var flat_diff = Vector3(diff.x, 0, diff.z)
	var distance = flat_diff.length()

	# Sersemleme (Stagger / Downed) - Yerde hareketsiz bekleme ve sarı parlama
	if is_staggered:
		stagger_timer += delta * 15.0
		var pulse = (sin(stagger_timer) + 1.0) * 0.5
		sprite.modulate = Color.WHITE.lerp(Color(3.0, 1.4, 0.2, 1.0), pulse)
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)
		move_and_slide()
		return

	# Zamanlayıcı güncellemeleri (Kare başı hesaplama yükünü azaltır)
	los_timer -= delta
	if los_timer <= 0.0:
		los_timer = randf_range(0.18, 0.25)
		cached_has_los = _has_line_of_sight()

	sep_timer -= delta
	if sep_timer <= 0.0:
		sep_timer = randf_range(0.22, 0.32)
		cached_sep_dir = _calculate_separation()

	nav_timer -= delta
	if nav_timer <= 0.0:
		nav_timer = randf_range(0.20, 0.30)
		if nav_agent and player:
			nav_agent.target_position = player.global_position

	if attack_timer > 0.0:
		attack_timer -= delta
	if wall_slide_timer > 0.0:
		wall_slide_timer -= delta

	# Oyuncuyu tespit etme ve uyarılma
	if not is_alerted:
		if distance <= 24.0 and cached_has_los:
			is_alerted = true

	# Hız belirleme: Uyarılınca tam hız / yakınsa hücum hızı, uzaktayken temkinli yaklaşma
	var current_target_speed = move_speed
	if is_alerted:
		current_target_speed = move_speed * (1.2 if distance < 8.0 else 1.0)
	else:
		current_target_speed = move_speed * 0.55

	# HOP stili zıplama
	if walk_style == WalkStyle.HOP and is_on_floor():
		var hop_phase = sin(anim_timer * anim_speed)
		if hop_phase > 0.8:
			current_target_speed *= 1.5
			velocity.y = 3.5

	# Rota belirleme (NavAgent + Görüş Hattı)
	var raw_dir = flat_diff.normalized()
	var path_dir = raw_dir

	if not cached_has_los and nav_agent and not nav_agent.is_navigation_finished():
		var next_point = nav_agent.get_next_path_position()
		var to_next = next_point - global_position
		to_next.y = 0.0
		if to_next.length_squared() > 0.04:
			path_dir = to_next.normalized()
	elif not cached_has_los:
		path_dir = _steer_around_obstacles(raw_dir)

	var final_dir = (path_dir + cached_sep_dir * 0.35).normalized()

	var target_vel = final_dir * current_target_speed
	velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta)

	# Yakın temas saldırısı
	if distance <= attack_range and attack_timer <= 0.0:
		_perform_melee_attack(raw_dir)

	var h_speed = Vector2(velocity.x, velocity.z).length()
	move_and_slide()
	_process_walk_style(delta, h_speed)


func _has_line_of_sight() -> bool:
	if not player:
		return false
	var space_state = get_world_3d().direct_space_state
	var from = global_position + Vector3(0, 1.2, 0)
	var to = player.global_position + Vector3(0, 1.2, 0)
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1 # Duvarlar
	var result = space_state.intersect_ray(query)
	return result.is_empty()

func _steer_around_obstacles(desired_dir: Vector3) -> Vector3:
	var space_state = get_world_3d().direct_space_state
	var from = global_position + Vector3(0, 0.6, 0)
	var forward_to = from + desired_dir * 2.2
	
	var q = PhysicsRayQueryParameters3D.create(from, forward_to)
	q.collision_mask = 1 # Duvarlar, sütunlar
	q.exclude = [self]
	
	if space_state.intersect_ray(q).is_empty():
		return desired_dir
	
	# Eğer önceden seçilmiş bir sıyrılma yönü varsa onu koru (köşe titremesini önler)
	if wall_slide_timer > 0.0 and abs(wall_slide_bias) > 0.1:
		var biased_dir = desired_dir.rotated(Vector3.UP, deg_to_rad(55.0 * wall_slide_bias))
		var q_bias = PhysicsRayQueryParameters3D.create(from, from + biased_dir * 1.8)
		q_bias.collision_mask = 1
		q_bias.exclude = [self]
		if space_state.intersect_ray(q_bias).is_empty():
			return biased_dir

	# Yeni sıyrılma yönü belirle
	var right_dir = desired_dir.rotated(Vector3.UP, deg_to_rad(55.0))
	var left_dir = desired_dir.rotated(Vector3.UP, deg_to_rad(-55.0))
	
	var q_right = PhysicsRayQueryParameters3D.create(from, from + right_dir * 2.0)
	q_right.collision_mask = 1
	q_right.exclude = [self]
	var right_hit = not space_state.intersect_ray(q_right).is_empty()
	
	var q_left = PhysicsRayQueryParameters3D.create(from, from + left_dir * 2.0)
	q_left.collision_mask = 1
	q_left.exclude = [self]
	var left_hit = not space_state.intersect_ray(q_left).is_empty()
	
	if not right_hit:
		wall_slide_bias = 1.0
		wall_slide_timer = 0.45
		return right_dir
	elif not left_hit:
		wall_slide_bias = -1.0
		wall_slide_timer = 0.45
		return left_dir
	else:
		return desired_dir.rotated(Vector3.UP, deg_to_rad(85.0))

func _calculate_separation() -> Vector3:
	var sep = Vector3.ZERO
	var enemies = get_tree().get_nodes_in_group("enemy")
	for other in enemies:
		if other == self or not is_instance_valid(other):
			continue
		var to_self = global_position - other.global_position
		var d = to_self.length()
		if d < 1.6 and d > 0.05:
			sep += (to_self.normalized() / d)
	sep.y = 0.0
	return sep.normalized() if sep.length_squared() > 0.01 else Vector3.ZERO

func _perform_melee_attack(dir_to_player: Vector3) -> void:
	attack_timer = attack_cooldown
	# Oyuncuya doğru öne hamle (lunge)
	velocity += dir_to_player * 7.0
	
	# Saldırı görsel darbesi
	if sprite:
		var attack_tween = create_tween()
		attack_tween.tween_property(sprite, "scale", Vector3(1.3, 1.3, 1.0), 0.1)
		attack_tween.tween_property(sprite, "scale", Vector3.ONE, 0.15)
	
	if player and player.has_method("take_damage"):
		player.take_damage(attack_damage, global_position)

func _process_walk_style(delta: float, speed: float) -> void:
	if not sprite or is_dead:
		return

	anim_timer += delta

	match walk_style:
		WalkStyle.WADDLE:
			_animate_waddle(delta, speed)
		WalkStyle.HOP:
			_animate_hop(delta, speed)
		WalkStyle.SKITTER:
			_animate_skitter(delta, speed)
		WalkStyle.FLOAT:
			_animate_float(delta, speed)

func _animate_waddle(delta: float, speed: float) -> void:
	if speed > 0.3:
		var t = anim_timer * anim_speed
		var tilt = sin(t * 0.5) * deg_to_rad(tilt_amount)
		sprite.rotation.z = lerp_angle(sprite.rotation.z, tilt, 14.0 * delta)
		var bounce = abs(sin(t)) * bounce_amount
		var stretch = sin(t) * 0.05
		sprite.scale = Vector3(base_scale.x * (1.0 - stretch), base_scale.y * (1.0 + stretch), base_scale.z)
		# Zemin altına batmayı önleyen dikey eksen dengelemesi (Ayaklar zeminde kalır)
		var ground_compensation = (sprite.scale.y - base_scale.y) * sprite_half_height
		sprite.position.y = lerp(sprite.position.y, base_sprite_y + bounce + ground_compensation, 14.0 * delta)
	else:
		sprite.rotation.z = lerp_angle(sprite.rotation.z, 0.0, 8.0 * delta)
		var breathe = sin(anim_timer * 2.5) * 0.02
		sprite.scale = Vector3(base_scale.x, base_scale.y * (1.0 + breathe), base_scale.z)
		var ground_compensation = (sprite.scale.y - base_scale.y) * sprite_half_height
		sprite.position.y = lerp(sprite.position.y, base_sprite_y + ground_compensation, 6.0 * delta)

func _animate_hop(delta: float, speed: float) -> void:
	if speed > 0.3:
		var t = anim_timer * anim_speed
		var squish = sin(t)
		if squish < 0.0:
			# Zıplama öncesi yere çöküş
			sprite.scale = Vector3(base_scale.x * 1.15, base_scale.y * 0.85, base_scale.z)
		else:
			# Havada uzama
			sprite.scale = Vector3(base_scale.x * 0.85, base_scale.y * 1.2, base_scale.z)
		var ground_compensation = (sprite.scale.y - base_scale.y) * sprite_half_height
		sprite.position.y = lerp(sprite.position.y, base_sprite_y + ground_compensation, 14.0 * delta)
		sprite.rotation.z = lerp_angle(sprite.rotation.z, 0.0, 10.0 * delta)
	else:
		sprite.scale = lerp(sprite.scale, base_scale, 10.0 * delta)
		sprite.position.y = lerp(sprite.position.y, base_sprite_y, 10.0 * delta)

func _animate_skitter(delta: float, speed: float) -> void:
	if speed > 0.3:
		var t = anim_timer * (anim_speed * 2.5)
		var jitter = sin(t) * deg_to_rad(tilt_amount * 0.6)
		sprite.rotation.z = jitter
		var stretch = sin(t) * 0.04
		sprite.scale = Vector3(base_scale.x * (1.0 + stretch), base_scale.y * (1.0 - stretch), base_scale.z)
		var ground_compensation = (sprite.scale.y - base_scale.y) * sprite_half_height
		sprite.position.y = base_sprite_y + ground_compensation
	else:
		sprite.rotation.z = lerp_angle(sprite.rotation.z, 0.0, 12.0 * delta)
		sprite.scale = lerp(sprite.scale, base_scale, 12.0 * delta)
		sprite.position.y = lerp(sprite.position.y, base_sprite_y, 12.0 * delta)

func _animate_float(delta: float, _speed: float) -> void:
	# Havada süzülen dalgalanma
	var float_offset = sin(anim_timer * 3.0) * 0.2
	sprite.position.y = lerp(sprite.position.y, base_sprite_y + float_offset + 0.5, 6.0 * delta)
	sprite.rotation.z = sin(anim_timer * 1.5) * deg_to_rad(5.0)

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO, hit_point: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return

	is_alerted = true

	# Kafa Vuruşu (Headshot) Tespiti: Sprite yüksekliğinin üst %30'luk dilimi
	var is_headshot = false
	if hit_point != Vector3.ZERO:
		var head_threshold = global_position.y + base_sprite_y + (sprite_half_height * 0.35)
		if hit_point.y >= head_threshold:
			is_headshot = true

	var final_damage = amount * (2.2 if is_headshot else 1.0)
	current_health -= final_damage
	velocity += knockback * (1.3 if is_headshot else 1.0)

	if is_headshot:
		ComicPopup.spawn(get_parent(), hit_point + Vector3(0, 0.5, 0), "BOOM", 1.2)
		SoundFX.play_sound("finisher", 1.5)

	# 1. Kağıt Parçacıkları (Paper Confetti/Gibs)
	if HIT_PARTICLES:
		var p = HIT_PARTICLES.instantiate()
		get_parent().add_child(p)
		var spawn_p = hit_point if hit_point != Vector3.ZERO else global_position + Vector3(0, 0.8, 0)
		p.activate(spawn_p, knockback)


	# 2. Vuruş Reaksiyonu (Hasar parıltısı ve darbe yamulması)
	if damage_tween and damage_tween.is_valid():
		damage_tween.kill()

	damage_tween = create_tween()
	# Parlak flaş ve darbe yönüne ezilme
	sprite.modulate = Color(3.5, 3.5, 3.5, 1.0)
	sprite.scale = Vector3(base_scale.x * 1.3, base_scale.y * 0.7, base_scale.z)
	var hit_tilt = (randf() - 0.5) * deg_to_rad(24.0)
	sprite.rotation.z += hit_tilt

	damage_tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.14)
	damage_tween.parallel().tween_property(sprite, "scale", base_scale, 0.14)
	damage_tween.parallel().tween_property(sprite, "rotation:z", 0.0, 0.2)

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
	
	# Yere düşme ve infaz bekleme görseli (öne eğilme / çökme)
	if sprite:
		var dt = create_tween()
		dt.tween_property(sprite, "rotation:z", deg_to_rad(75.0), 0.25).set_trans(Tween.TRANS_BOUNCE)
		dt.parallel().tween_property(sprite, "position:y", 0.35, 0.25)
	
	# 3 saniye sonra infaz edilmezse kendiliğinden ölür
	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(func():
		if is_instance_valid(self) and not is_dead:
			_die(Vector3.UP * 2.0, false)
	)

func execute() -> void:
	if is_dead:
		return
	_die(Vector3.UP * 6.0, true)

func _die(death_impulse: Vector3 = Vector3.ZERO, is_finisher: bool = false) -> void:
	is_dead = true
	is_staggered = false

	set_collision_layer_value(3, false) # Katman 3: Düşmanlar (Değer 4)
	set_collision_mask_value(1, false)
	set_collision_mask_value(2, false)
	if collision_shape:
		collision_shape.disabled = true


	# Eşya düşürme
	_spawn_loot(is_finisher)


	if is_finisher:
		# DOOM TARZI ORTADAN İKİYE YARMA İNFAZI
		_spawn_split_halves(death_impulse)
	else:
		_spawn_paper_corpse()
		var death_tween = create_tween()
		velocity += death_impulse * 1.5 + Vector3(0, 3.0, 0)
		death_tween.parallel().tween_property(sprite, "scale:y", 0.02, 0.3).set_trans(Tween.TRANS_QUAD)
		death_tween.parallel().tween_property(sprite, "scale:x", base_scale.x * 1.6, 0.3)
		death_tween.parallel().tween_property(sprite, "position:y", 0.04, 0.3)
		death_tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.45)
		death_tween.tween_callback(queue_free)

func _spawn_paper_corpse() -> void:
	if not CORPSE_TEX:
		return
	var corpse = Sprite3D.new()
	corpse.texture = CORPSE_TEX
	corpse.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	corpse.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	corpse.scale = Vector3(0.45, 0.45, 0.45)
	get_parent().add_child(corpse)
	corpse.global_position = Vector3(global_position.x, 0.15, global_position.z)
	# 45 saniye sonra yavaşça kaybolsun
	var tw = corpse.create_tween()
	tw.tween_interval(35.0)
	tw.tween_property(corpse, "modulate:a", 0.0, 5.0)
	tw.tween_callback(corpse.queue_free)

func _spawn_split_halves(death_impulse: Vector3) -> void:
	if not sprite or not sprite.texture:
		queue_free()
		return
	
	sprite.visible = false
	var tex = sprite.texture
	var tex_w = tex.get_width()
	var tex_h = tex.get_height()
	var half_w = float(tex_w) / 2.0
	
	# Kamera yatay düzlemi (Parçaların ekrana göre tam sağa ve sola ayrılması için)
	var cam = get_viewport().get_camera_3d() if get_viewport() else null
	var cam_right = cam.global_transform.basis.x.normalized() if cam else Vector3.RIGHT
	cam_right.y = 0.0
	cam_right = cam_right.normalized()

	# Parçaların merkezden kayma mesafesi (tam sticker oluşturacak başlangıç offseti)
	var half_pixel_offset = (half_w * 0.5) * sprite.pixel_size * sprite.scale.x
	var center_pos = sprite.global_position

	# Sol Yarı (Sol sticker parçası)
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
	
	# Sağ Yarı (Sağ sticker parçası)
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

	# Yırtılma anında merkezde kağıt parçacıkları saçılması
	if HIT_PARTICLES:
		var p = HIT_PARTICLES.instantiate()
		get_parent().add_child(p)
		p.amount = 45
		p.activate(center_pos, Vector3.UP * 4.5 + death_impulse * 0.5)

	# 1. Aşama: Yırtılma Gerilimi ve Çatlama (Tear Snap)
	var rip_seq = create_tween()
	var rip_start_left = left_half.global_position - cam_right * 0.35
	var rip_start_right = right_half.global_position + cam_right * 0.35

	rip_seq.parallel().tween_property(left_half, "global_position", rip_start_left, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	rip_seq.parallel().tween_property(left_half, "rotation:z", deg_to_rad(-14.0), 0.08)
	rip_seq.parallel().tween_property(right_half, "global_position", rip_start_right, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	rip_seq.parallel().tween_property(right_half, "rotation:z", deg_to_rad(14.0), 0.08)

	# 2. Aşama: Şiddetli İkiye Ayrılma ve Yere Süzülüş (Violent Split & Float)
	var left_final = left_half.global_position - cam_right * 2.2 + Vector3(0, -1.2, 0)
	var right_final = right_half.global_position + cam_right * 2.2 + Vector3(0, -1.2, 0)

	rip_seq.tween_property(left_half, "global_position", left_final, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rip_seq.parallel().tween_property(left_half, "rotation:z", deg_to_rad(-70.0), 0.45)
	rip_seq.parallel().tween_property(left_half, "modulate:a", 0.0, 0.45)

	rip_seq.parallel().tween_property(right_half, "global_position", right_final, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rip_seq.parallel().tween_property(right_half, "rotation:z", deg_to_rad(70.0), 0.45)
	rip_seq.parallel().tween_property(right_half, "modulate:a", 0.0, 0.45)

	rip_seq.tween_callback(func():
		_spawn_paper_corpse()
		if is_instance_valid(left_half): left_half.queue_free()
		if is_instance_valid(right_half): right_half.queue_free()
		queue_free()
	)



func _spawn_loot(is_guaranteed: bool) -> void:
	if is_guaranteed:
		# İnfaz (Glory Kill): Bol can, zırh ve mermi saçar
		if HEALTH_PICKUP:
			_drop_pickup(HEALTH_PICKUP)
		if ARMOR_PICKUP:
			_drop_pickup(ARMOR_PICKUP)
		if AMMO_PICKUP:
			_drop_pickup(AMMO_PICKUP)
	else:
		# Normal ölüm: Düşme olasılıkları
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
	var offset = Vector3(randf_range(-0.4, 0.4), 0.8, randf_range(-0.4, 0.4))
	item.global_position = global_position + offset

