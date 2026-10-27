extends CharacterBody3D
class_name Player

enum WeaponType { FISTS, PISTOL, SHOTGUN, ROCKET }

# --- Can ve Zırh Ayarları ---
@export_group("Sağlık ve Zırh")
@export var max_health: float = 100.0
@export var max_armor: float = 100.0
@export var health_regen_delay: float = 3.5
@export var health_regen_rate: float = 12.0


# --- Hareket Ayarları ---
@export_group("Hız ve İvme")
@export var walk_speed: float = 12.0
@export var acceleration: float = 60.0
@export var friction: float = 40.0
@export var air_acceleration: float = 25.0
@export var air_friction: float = 3.0
@export var jump_velocity: float = 7.5
@export var gravity: float = 24.0

# --- Dash (Atılma) Ayarları ---
@export_group("Dash")
@export var dash_speed: float = 28.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.8

# --- Slide (Kayma) Ayarları ---
@export_group("Slide")
@export var slide_initial_boost: float = 16.0
@export var slide_friction: float = 22.0
@export var slide_min_speed: float = 3.5
@export var slide_max_duration: float = 0.65
@export var slide_cooldown: float = 0.35

# --- El Sallanma Ayarları ---
@export_group("El Animasyonu")
@export var hand_bob_speed: float = 14.0
@export var hand_bob_amount_x: float = 18.0
@export var hand_bob_amount_y: float = 10.0

# --- Kamera Ayarları ---
@export_group("Kamera")
@export var mouse_sensitivity: float = 0.002
@export var normal_fov: float = 90.0
@export var dash_fov: float = 105.0
@export var slide_fov: float = 95.0

# --- Düğüm Referansları ---
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var ceiling_check: RayCast3D = $CeilingCheck
@onready var hand_container: Control = $UI/HandContainer
@onready var hand_sprite: Sprite2D = $UI/HandContainer/HandSprite
@onready var fist_container: Control = $UI/HandContainer/FistContainer
@onready var fist_left: Sprite2D = $UI/HandContainer/FistContainer/FistLeft
@onready var fist_right: Sprite2D = $UI/HandContainer/FistContainer/FistRight
@onready var damage_overlay: ColorRect = $UI/DamageOverlay
@onready var splatter_overlay: ColorRect = $UI/SplatterOverlay
@onready var health_label: Label = $UI/HUDLeft/HealthBarContainer/HealthLabel
@onready var health_bar: Range = $UI/HUDLeft/HealthBarContainer/HealthBar
@onready var armor_label: Label = $UI/HUDLeft/ArmorBarContainer/ArmorLabel
@onready var armor_bar: Range = $UI/HUDLeft/ArmorBarContainer/ArmorBar
@onready var ammo_label: Label = $UI/HUDRight/AmmoLabel

@onready var death_screen: Control = $UI/DeathScreen
@onready var glory_indicator: Label = $UI/GloryIndicator
@onready var fps_counter: Label = $UI/FPSCounter
@onready var hit_marker: Label = $UI/HitMarker
@onready var pistol_muzzle: Marker2D = $UI/HandContainer/HandSprite/PistolMuzzle
@onready var shotgun_muzzle: Marker2D = $UI/HandContainer/HandSprite/ShotgunMuzzle
@onready var rocket_muzzle: Marker2D = $UI/HandContainer/HandSprite/RocketMuzzle
@onready var muzzle_flash: Sprite2D = $UI/HandContainer/MuzzleFlash
@onready var muzzle_omni_light: OmniLight3D = $Head/Camera3D/MuzzleOmniLight
@onready var retro_filter: ColorRect = $UI/RetroPixelFilter
@onready var style_rank_label: Label = $UI/StyleMeter/StyleRank
@onready var style_bar: ProgressBar = $UI/StyleMeter/StyleBar
@onready var berserk_label: Label = $UI/BerserkIndicator
@onready var yellow_key_badge: Label = $UI/HUDLeft/PortraitRow/YellowKeyBadge
@onready var objective_notice: Label = $UI/ObjectiveNotice
@onready var victory_screen: Control = $UI/VictoryScreen
@onready var victory_stats: Label = $UI/VictoryScreen/VictoryStats
@onready var boss_bar_container: VBoxContainer = $UI/BossBarContainer
@onready var boss_name_label: Label = $UI/BossBarContainer/BossNameLabel
@onready var boss_health_bar: ProgressBar = $UI/BossBarContainer/BossHealthBar

var has_yellow_key: bool = false
var level_start_time: float = 0.0
var is_level_complete: bool = false

var style_score: float = 0.0
var style_decay_rate: float = 18.0
var is_berserk: bool = false
var berserk_timer: float = 0.0
var berserk_duration: float = 10.0

var fist_left_base_pos: Vector2 = Vector2(-280, -90)
var fist_right_base_pos: Vector2 = Vector2(280, -90)
var punch_combo_left: bool = true
var fist_tween_left: Tween = null
var fist_tween_right: Tween = null
var shotgun_popup_spawned: bool = false

var trauma: float = 0.0
var max_shake_offset: float = 0.08
var max_shake_roll: float = 0.05
var hit_marker_tween: Tween = null

const BULLET_TRACER = preload("res://scenes/effects/bullet_tracer.tscn")
const TEXTURE_PISTOL = preload("res://assets/Weapons/w_pistol.png")
const TEXTURE_SHOTGUN = preload("res://assets/Weapons/w_pomp.png")
const TEXTURE_ROCKET = preload("res://assets/Weapons/w_rocket.png")
const ROCKET_SCENE = preload("res://scenes/projectiles/player_rocket.tscn")

# --- Silah Parametreleri ---
var current_weapon: WeaponType = WeaponType.FISTS
var has_pistol: bool = false
var has_shotgun: bool = false
var has_rocket: bool = false

var pistol_ammo: int = 30
var pistol_max_ammo: int = 30
var pistol_reserve: int = 60

var shotgun_ammo: int = 2
var shotgun_max_ammo: int = 2
var shotgun_reserve: int = 12

var rocket_ammo: int = 1
var rocket_max_ammo: int = 1
var rocket_reserve: int = 4

var is_reloading: bool = false
var reload_timer: float = 0.0
var fire_cooldown_timer: float = 0.0
var is_switching_weapon: bool = false

# --- Durum Değişkenleri ---
var current_health: float
var current_armor: float
var health_regen_timer: float = 0.0
var is_dead: bool = false

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector3 = Vector3.ZERO

var is_sliding: bool = false
var slide_direction: Vector3 = Vector3.ZERO
var slide_timer: float = 0.0
var slide_cooldown_timer: float = 0.0

var standing_capsule_height: float = 2.0
var sliding_capsule_height: float = 1.0
var normal_head_y: float = 1.6
var sliding_head_y: float = 0.8

var hand_base_pos: Vector2 = Vector2.ZERO
var base_hand_scale: Vector2 = Vector2.ONE
var hand_bob_timer: float = 0.0
var hand_tween: Tween = null
var damage_overlay_tween: Tween = null

# Juice & Dinamik Hissiyat Değişkenleri
var mouse_input_accum: Vector2 = Vector2.ZERO
var weapon_sway_pos: Vector2 = Vector2.ZERO
var weapon_sway_rot: float = 0.0
var target_cam_roll: float = 0.0
var landing_impact: float = 0.0
var was_on_floor_last: bool = true
var step_timer: float = 0.0
var fov_kick: float = 0.0


func _ready() -> void:
	current_health = max_health
	current_armor = 50.0
	_update_hud()
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.fov = normal_fov
	_setup_default_inputs()
	if hand_sprite:
		hand_base_pos = Vector2(0, -90)
		hand_sprite.position = hand_base_pos
		hand_sprite.scale = Vector2(0.48, 0.48)
		base_hand_scale = hand_sprite.scale
		hand_sprite.visible = false
	if fist_container:
		fist_container.visible = true
	if fist_left:
		fist_left_base_pos = fist_left.position
	if fist_right:
		fist_right_base_pos = fist_right.position
	level_start_time = Time.get_ticks_msec() / 1000.0
	_update_hud()

func _input(event: InputEvent) -> void:
	if is_dead or is_level_complete:
		if event.is_action_pressed("reload"):
			get_tree().reload_current_scene()
		return

	# Silah Değiştirme (1 = Yumruklar, 2 = Tabanca, 3 = Pompalı, 4 = Roketatar)
	if event.is_action_pressed("weapon_1") and current_weapon != WeaponType.FISTS and not is_switching_weapon:
		_switch_weapon(WeaponType.FISTS)
	elif event.is_action_pressed("weapon_2") and has_pistol and current_weapon != WeaponType.PISTOL and not is_switching_weapon:
		_switch_weapon(WeaponType.PISTOL)
	elif event.is_action_pressed("weapon_3") and has_shotgun and current_weapon != WeaponType.SHOTGUN and not is_switching_weapon:
		_switch_weapon(WeaponType.SHOTGUN)
	elif event.is_action_pressed("weapon_4") and has_rocket and current_weapon != WeaponType.ROCKET and not is_switching_weapon:
		_switch_weapon(WeaponType.ROCKET)
	elif event.is_action_pressed("weapon_next") and not is_switching_weapon:
		var available_weapons: Array[WeaponType] = [WeaponType.FISTS]
		if has_pistol: available_weapons.append(WeaponType.PISTOL)
		if has_shotgun: available_weapons.append(WeaponType.SHOTGUN)
		if has_rocket: available_weapons.append(WeaponType.ROCKET)
		
		var cur_idx = available_weapons.find(current_weapon)
		var next_idx = (cur_idx + 1) % available_weapons.size()
		_switch_weapon(available_weapons[next_idx])

	# Finisher / İnfaz (V tuşu)
	if event.is_action_pressed("finisher"):
		_try_finisher()

	# Berserk Modu (B tuşu)
	if event.is_action_pressed("berserk"):
		_try_activate_berserk()

	# Şarjör Yenileme (R tuşu)
	if event.is_action_pressed("reload") and not is_reloading:
		_try_reload()

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_input_accum += event.relative
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-62.0), deg_to_rad(85.0))


	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	if fps_counter:
		var fps = Engine.get_frames_per_second()
		fps_counter.text = "%d FPS" % fps
		if fps >= 55:
			fps_counter.modulate = Color(0.3, 1.0, 0.4)
		elif fps >= 30:
			fps_counter.modulate = Color(1.0, 0.85, 0.2)
		else:
			fps_counter.modulate = Color(1.0, 0.3, 0.3)

func _physics_process(delta: float) -> void:
	if is_dead:
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return

	# Stil ve Berserk Güncellemesi
	_process_style_meter(delta)
	_process_berserk(delta)

	# Zamanlayıcılar
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
	if slide_cooldown_timer > 0.0:
		slide_cooldown_timer -= delta
	if fire_cooldown_timer > 0.0:
		fire_cooldown_timer -= delta
		
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			_finish_reload()

	# Yerçekimi
	if not is_on_floor() and not is_dashing:
		velocity.y -= gravity * delta

	# Girdi yönü
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var move_direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Ateş etme (Sol Tık)
	if Input.is_action_pressed("shoot") and fire_cooldown_timer <= 0.0 and not is_reloading and not is_switching_weapon:
		_shoot()

	# Dash tetikleme
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and not is_dashing:
		_start_dash(move_direction)

	# Slide tetikleme & sonlandırma (Yalnızca anlık basışta ve bekleme süresi bittiğinde)
	if Input.is_action_just_pressed("slide") and is_on_floor() and not is_sliding and not is_dashing and slide_cooldown_timer <= 0.0:
		var current_speed = Vector2(velocity.x, velocity.z).length()
		if current_speed > 2.0 or move_direction.length_squared() > 0.1:
			_start_slide(move_direction)
	elif not is_on_floor() and is_sliding:
		if not ceiling_check.is_colliding():
			_stop_slide()

	# Hareket işlemleri
	if is_dashing:
		_process_dash(delta)
	elif is_sliding:
		_process_slide(delta)
	else:
		_process_normal_movement(delta, move_direction)

	# Zıplama
	if Input.is_action_just_pressed("jump") and is_on_floor():
		if is_sliding and not ceiling_check.is_colliding():
			_stop_slide()
		velocity.y = jump_velocity
		SoundFX.play_sound("jump", -2.0)

	var h_speed = Vector2(velocity.x, velocity.z).length()
	var prev_vel_y = velocity.y
	move_and_slide()

	# Yere iniş yaylanması ve iniş sesi (Landing impact)
	if not was_on_floor_last and is_on_floor() and prev_vel_y < -4.0:
		landing_impact = clamp(abs(prev_vel_y) * 2.2, 8.0, 24.0)
		SoundFX.play_sound("land", -1.0)
	was_on_floor_last = is_on_floor()

	# Adım Sesleri (Footsteps)
	if is_on_floor() and not is_sliding and not is_dashing and h_speed > 1.5:
		step_timer += delta * (h_speed / walk_speed) * 12.0
		if step_timer >= PI:
			step_timer = 0.0
			SoundFX.play_sound("footstep", -6.0)
	else:
		step_timer = 0.0

	# Strafe Kamera Eğimi (A/D ile sağa-sola yatış)
	var local_x_vel = transform.basis.inverse() * velocity
	var strafe_factor = clamp(local_x_vel.x / walk_speed, -1.0, 1.0)
	target_cam_roll = -strafe_factor * deg_to_rad(2.4)
	if is_sliding:
		target_cam_roll += deg_to_rad(3.5) # Slide anında agresif yatış

	_update_camera_effects(delta)
	_update_hand_bobbing(delta, h_speed)
	_check_glory_kill_prompt()


func _shoot() -> void:
	match current_weapon:
		WeaponType.FISTS:
			_shoot_fists()
		WeaponType.PISTOL:
			_shoot_pistol()
		WeaponType.SHOTGUN:
			_shoot_shotgun()
		WeaponType.ROCKET:
			_shoot_rocket()

func _shoot_fists() -> void:
	fire_cooldown_timer = 0.20
	
	# Sol / Sağ dönüşümlü yumruk animasyonu
	if punch_combo_left:
		if fist_tween_left and fist_tween_left.is_valid():
			fist_tween_left.kill()
		fist_tween_left = create_tween()
		# İleri ve merkeze doğru ani hamle (sol kroşe)
		fist_tween_left.tween_property(fist_left, "position", Vector2(-70.0, -170.0), 0.06).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		fist_tween_left.parallel().tween_property(fist_left, "scale", Vector2(0.68, 0.68), 0.06)
		fist_tween_left.tween_property(fist_left, "position", fist_left_base_pos, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		fist_tween_left.parallel().tween_property(fist_left, "scale", Vector2(0.52, 0.52), 0.14)
		punch_combo_left = false
	else:
		if fist_tween_right and fist_tween_right.is_valid():
			fist_tween_right.kill()
		fist_tween_right = create_tween()
		# İleri ve merkeze doğru ani hamle (sağ aparkat)
		fist_tween_right.tween_property(fist_right, "position", Vector2(70.0, -170.0), 0.06).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		fist_tween_right.parallel().tween_property(fist_right, "scale", Vector2(0.68, 0.68), 0.06)
		fist_tween_right.tween_property(fist_right, "position", fist_right_base_pos, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		fist_tween_right.parallel().tween_property(fist_right, "scale", Vector2(0.52, 0.52), 0.14)
		punch_combo_left = true

	# Yakın temas menzili vuruş kontrolü (Melee raycast 3.6m)
	var space_state = get_world_3d().direct_space_state
	var from = camera.global_position
	var dir = -camera.global_transform.basis.z.normalized()
	var to = from + dir * 3.6

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 5 # Dünya (1) + Düşmanlar (4)
	query.exclude = [self]

	var result = space_state.intersect_ray(query)
	if result:
		var collider = result.collider
		var hit_pos = result.position
		var knockback = (dir + Vector3(0, 0.35, 0)).normalized() * 32.0

		SoundFX.play_sound("punch_hit", 3.0)
		_trigger_hit_marker()
		add_trauma(0.25)
		_apply_hitstop(0.04)
		add_style_points(15.0, "MELEE SMASH")

		if collider.has_method("take_damage"):
			var punch_dmg = 50.0 * (2.5 if is_berserk else 1.0)
			collider.take_damage(punch_dmg, knockback, hit_pos)
			ComicPopup.spawn(get_parent(), hit_pos + Vector3(0, 0.4, 0), "POW", 1.1)
	else:
		# Boşa savurma sesi
		SoundFX.play_sound("punch_swing", 1.2)
		add_trauma(0.06)

func _shoot_rocket() -> void:
	if rocket_ammo <= 0:
		SoundFX.play_sound("empty", -4.0)
		_try_reload()
		return

	rocket_ammo -= 1
	fire_cooldown_timer = 0.9
	_update_hud()
	_animate_hand_recoil(80.0)
	fov_kick = 8.0
	head.rotation.x = clamp(head.rotation.x + deg_to_rad(4.0), deg_to_rad(-89.0), deg_to_rad(89.0))
	add_trauma(0.65)
	SoundFX.play_sound("rocket_fire", 2.0)
	_show_muzzle_flash(rocket_muzzle, 0.75)

	if ROCKET_SCENE:
		var rocket = ROCKET_SCENE.instantiate()
		get_parent().add_child(rocket)

		var muzzle_pos: Vector3
		if rocket_muzzle and is_instance_valid(rocket_muzzle):
			muzzle_pos = camera.project_position(rocket_muzzle.global_position, 0.5)
		else:
			muzzle_pos = camera.global_position + (-camera.global_transform.basis.z * 0.45) - (camera.global_transform.basis.y * 0.16)

		# Hedef noktayı kamera ortasındaki raycast ile bul
		var space_state = get_world_3d().direct_space_state
		var from = camera.global_position
		var to = from - camera.global_transform.basis.z * 120.0
		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.collision_mask = 5
		query.exclude = [self]
		var result = space_state.intersect_ray(query)

		var target_pos = result.position if result else to
		var fly_dir = (target_pos - muzzle_pos).normalized()
		rocket.setup(muzzle_pos, fly_dir)

func _shoot_pistol() -> void:
	if pistol_ammo <= 0:
		SoundFX.play_sound("empty", -4.0)
		_try_reload()
		return

	pistol_ammo -= 1
	fire_cooldown_timer = 0.18
	_update_hud()
	_animate_hand_recoil(32.0)
	fov_kick = 2.5
	head.rotation.x = clamp(head.rotation.x + deg_to_rad(1.2), deg_to_rad(-89.0), deg_to_rad(89.0))
	add_trauma(0.22)
	SoundFX.play_sound("pistol", 1.0)
	_show_muzzle_flash(pistol_muzzle, 0.42)

	# Hitscan + Comic Tracer
	_fire_ray(30.0, 16.0, 0.0, Color(0.8, 2.2, 2.8, 1.0))

func _shoot_shotgun() -> void:
	if shotgun_ammo <= 0:
		SoundFX.play_sound("empty", -4.0)
		_try_reload()
		return

	shotgun_ammo -= 1
	fire_cooldown_timer = 0.75
	_update_hud()
	_animate_hand_recoil(58.0)
	fov_kick = 6.0
	head.rotation.x = clamp(head.rotation.x + deg_to_rad(3.2), deg_to_rad(-89.0), deg_to_rad(89.0))
	add_trauma(0.55)
	SoundFX.play_sound("shotgun", 2.5)
	_show_muzzle_flash(shotgun_muzzle, 0.65)

	# Pompalı: 10 adet saçılmalı (spread) saçma, yüksek darbe gücü
	shotgun_popup_spawned = false
	var pellet_count = 10
	for i in range(pellet_count):
		var spread_angle = 0.055 # Koni açısı
		_fire_ray(18.0, 28.0, spread_angle, Color(3.5, 1.2, 0.3, 1.0))

func _show_muzzle_flash(muzzle_node: Marker2D, flash_scale: float) -> void:
	if muzzle_omni_light:
		muzzle_omni_light.visible = true
		muzzle_omni_light.light_energy = 4.2
		var lt = create_tween()
		lt.tween_property(muzzle_omni_light, "light_energy", 0.0, 0.06)
		lt.tween_callback(func(): muzzle_omni_light.visible = false)

	if not muzzle_flash:
		return
	if muzzle_node and is_instance_valid(muzzle_node):
		muzzle_flash.global_position = muzzle_node.global_position
	muzzle_flash.scale = Vector2(flash_scale, flash_scale) * randf_range(0.9, 1.2)
	muzzle_flash.rotation = randf() * TAU
	muzzle_flash.visible = true
	var ft = create_tween()
	ft.tween_property(muzzle_flash, "scale", muzzle_flash.scale * 1.2, 0.04)
	ft.tween_callback(func(): muzzle_flash.visible = false)

func _fire_ray(damage: float, knockback: float, spread: float, tracer_color: Color) -> void:
	var space_state = get_world_3d().direct_space_state
	var from = camera.global_position
	
	# Bakış yönü + rastgele saçılma
	var dir = -camera.global_transform.basis.z.normalized()
	if spread > 0.0:
		var right = camera.global_transform.basis.x.normalized()
		var up = camera.global_transform.basis.y.normalized()
		var rand_x = randf_range(-spread, spread)
		var rand_y = randf_range(-spread, spread)
		dir = (dir + right * rand_x + up * rand_y).normalized()

	var to = from + dir * 80.0
	var hit_pos = to

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 5 # Dünya (1) + Düşmanlar (4)
	query.exclude = [self]

	var result = space_state.intersect_ray(query)
	if result:
		hit_pos = result.position
		var collider = result.collider
		var knockback_vec = dir * knockback
		if collider.has_method("take_damage"):
			var applied_dmg = damage * (2.0 if is_berserk else 1.0)
			collider.take_damage(applied_dmg, knockback_vec, result.position)
			_trigger_hit_marker()
			SoundFX.play_sound("enemy_hit", 0.5)
			add_style_points(6.5, "HIT")
			
			if current_weapon == WeaponType.SHOTGUN and not shotgun_popup_spawned:
				shotgun_popup_spawned = true
				_apply_hitstop(0.035)
				add_style_points(12.0, "SHOTGUN BLAST")
				ComicPopup.spawn(get_parent(), result.position + Vector3(0, 0.5, 0), "BAM", 1.25)
			elif current_weapon == WeaponType.PISTOL and randf() < 0.35:
				ComicPopup.spawn(get_parent(), result.position + Vector3(0, 0.4, 0), "POW", 0.9)

	# Ultrakill Tracer Mermi İzi
	if BULLET_TRACER:
		var tracer = BULLET_TRACER.instantiate()
		get_parent().add_child(tracer)
		
		var active_muzzle = shotgun_muzzle if current_weapon == WeaponType.SHOTGUN else pistol_muzzle
		var muzzle_pos: Vector3
		if active_muzzle and is_instance_valid(active_muzzle):
			muzzle_pos = camera.project_position(active_muzzle.global_position, 0.45)
		else:
			muzzle_pos = camera.global_position + (-camera.global_transform.basis.z * 0.42) - (camera.global_transform.basis.y * 0.16)
			
		tracer.setup(muzzle_pos, hit_pos, tracer_color)

func add_trauma(amount: float) -> void:
	trauma = clamp(trauma + amount, 0.0, 1.0)

func _trigger_hit_marker() -> void:
	if not hit_marker:
		return
	if hit_marker_tween and hit_marker_tween.is_valid():
		hit_marker_tween.kill()
	hit_marker.modulate.a = 1.0
	hit_marker.scale = Vector2(1.3, 1.3)
	hit_marker_tween = create_tween()
	hit_marker_tween.parallel().tween_property(hit_marker, "modulate:a", 0.0, 0.12)
	hit_marker_tween.parallel().tween_property(hit_marker, "scale", Vector2.ONE, 0.12)


func _animate_hand_recoil(recoil_pixels: float) -> void:
	if hand_sprite:
		if hand_tween and hand_tween.is_valid():
			hand_tween.kill()
		hand_tween = create_tween()
		hand_sprite.position.y = hand_base_pos.y + recoil_pixels
		hand_tween.tween_property(hand_sprite, "position:y", hand_base_pos.y, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _switch_weapon(new_weapon: WeaponType) -> void:
	is_switching_weapon = true
	is_reloading = false
	
	# Silah saklanma ve çıkma animasyonu
	var st = create_tween()
	if hand_sprite and hand_sprite.visible:
		st.tween_property(hand_sprite, "position:y", hand_base_pos.y + 110.0, 0.10)
	if fist_container and fist_container.visible:
		st.parallel().tween_property(fist_left, "position:y", fist_left_base_pos.y + 120.0, 0.10)
		st.parallel().tween_property(fist_right, "position:y", fist_right_base_pos.y + 120.0, 0.10)

	st.tween_callback(func():
		current_weapon = new_weapon
		_update_hud()
		match current_weapon:
			WeaponType.FISTS:
				if hand_sprite:
					hand_sprite.visible = false
				if fist_container:
					fist_container.visible = true
					fist_left.position = fist_left_base_pos + Vector2(0, 100)
					fist_right.position = fist_right_base_pos + Vector2(0, 100)
			WeaponType.SHOTGUN:
				if fist_container:
					fist_container.visible = false
				if hand_sprite:
					hand_sprite.visible = true
					hand_sprite.texture = TEXTURE_SHOTGUN
					hand_sprite.scale = Vector2(0.55, 0.55)
					hand_base_pos = Vector2(0, -90)
			WeaponType.ROCKET:
				if fist_container:
					fist_container.visible = false
				if hand_sprite:
					hand_sprite.visible = true
					hand_sprite.texture = TEXTURE_ROCKET
					hand_sprite.scale = Vector2(0.42, 0.42)
					hand_base_pos = Vector2(0, -95)
			WeaponType.PISTOL:
				if fist_container:
					fist_container.visible = false
				if hand_sprite:
					hand_sprite.visible = true
					hand_sprite.texture = TEXTURE_PISTOL
					hand_sprite.scale = Vector2(0.48, 0.48)
					hand_base_pos = Vector2(0, -90)
	)

	st.tween_callback(func():
		if current_weapon == WeaponType.FISTS:
			var ft = create_tween()
			ft.parallel().tween_property(fist_left, "position:y", fist_left_base_pos.y, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			ft.parallel().tween_property(fist_right, "position:y", fist_right_base_pos.y, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			ft.tween_callback(func(): is_switching_weapon = false)
		else:
			var wt = create_tween()
			wt.tween_property(hand_sprite, "position:y", hand_base_pos.y, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			wt.tween_callback(func(): is_switching_weapon = false)
	)

func _try_reload() -> void:
	if is_reloading or is_switching_weapon or current_weapon == WeaponType.FISTS:
		return

	var needs_reload = false
	if current_weapon == WeaponType.PISTOL and pistol_ammo < pistol_max_ammo and pistol_reserve > 0:
		needs_reload = true
	elif current_weapon == WeaponType.SHOTGUN and shotgun_ammo < shotgun_max_ammo and shotgun_reserve > 0:
		needs_reload = true
	elif current_weapon == WeaponType.ROCKET and rocket_ammo < rocket_max_ammo and rocket_reserve > 0:
		needs_reload = true

	if not needs_reload:
		return

	is_reloading = true
	if current_weapon == WeaponType.PISTOL:
		reload_timer = 1.1
	elif current_weapon == WeaponType.SHOTGUN:
		reload_timer = 1.4
	else:
		reload_timer = 1.6
		
	if ammo_label:
		ammo_label.text = "DOLDURULUYOR..."
		ammo_label.modulate = Color(1, 0.8, 0.2, 1)

	if hand_sprite:
		var rt = create_tween()
		rt.tween_property(hand_sprite, "position:y", hand_base_pos.y + 90.0, 0.2)
		rt.tween_interval(reload_timer - 0.4)
		rt.tween_property(hand_sprite, "position:y", hand_base_pos.y, 0.2)

func _finish_reload() -> void:
	is_reloading = false
	if current_weapon == WeaponType.PISTOL:
		var needed = pistol_max_ammo - pistol_ammo
		var amt = min(needed, pistol_reserve)
		pistol_ammo += amt
		pistol_reserve -= amt
	elif current_weapon == WeaponType.SHOTGUN:
		var needed = shotgun_max_ammo - shotgun_ammo
		var amt = min(needed, shotgun_reserve)
		shotgun_ammo += amt
		shotgun_reserve -= amt
	elif current_weapon == WeaponType.ROCKET:
		var needed = rocket_max_ammo - rocket_ammo
		var amt = min(needed, rocket_reserve)
		rocket_ammo += amt
		rocket_reserve -= amt
	_update_hud()

# --- Finisher / Glory Kill (Doom Tarzı İnfaz) ---
func _try_finisher() -> void:
	var space_state = get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from - camera.global_transform.basis.z * 6.5

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 4
	query.exclude = [self]

	var result = space_state.intersect_ray(query)
	var target = null
	if result and result.collider:
		target = result.collider
	else:
		var enemies = get_tree().get_nodes_in_group("enemy")
		for e in enemies:
			if e is Node3D and e.get("is_dead") != true and e.get("is_staggered") == true:
				if global_position.distance_to(e.global_position) <= 6.0:
					target = e
					break

	if target and target.get("is_dead") != true and target.get("is_staggered") == true:
		_execute_enemy(target)


func _execute_enemy(target: Node3D) -> void:
	# 1. Düşmana doğru akıcı hamle (Snappy Dash-in)
	var enemy_pos = target.global_position
	var diff = enemy_pos - global_position
	var dir = Vector3(diff.x, 0, diff.z).normalized()
	velocity = Vector3.ZERO
	
	if dir.length_squared() > 0.001:
		var close_pos = enemy_pos - dir * 1.5
		close_pos.y = global_position.y
		
		# Anında teleport olmak yerine 0.08 saniyelik çok hızlı bir hamle
		var dash_tw = create_tween()
		dash_tw.tween_property(self, "global_position", close_pos, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		var target_angle_y = atan2(-dir.x, -dir.z)
		rotation.y = target_angle_y

	# Head pitch açısını düşmanın göğsüne ayarla
	var target_look_y = enemy_pos.y + 0.4
	var eye_y = global_position.y + head.position.y
	var dist_h = Vector2(diff.x, diff.z).length()
	var pitch = atan2(eye_y - target_look_y, dist_h)
	head.rotation.x = clamp(-pitch, deg_to_rad(-60.0), deg_to_rad(60.0))
	head.rotation.y = 0.0
	head.rotation.z = 0.0
	camera.rotation = Vector3.ZERO
	camera.fov = 100.0

	# Yumruk veya Silah İnfaz Görsel Hareketi
	if fist_container and fist_container.visible:
		# İki elle ortadan kavrayıp iki yana şiddetle yırtma animasyonu
		if fist_tween_left and fist_tween_left.is_valid(): fist_tween_left.kill()
		if fist_tween_right and fist_tween_right.is_valid(): fist_tween_right.kill()
		
		var rip_tw = create_tween().set_parallel(true)
		# 1. Adım: Merkeze atılıp kağıdı kavrama
		rip_tw.tween_property(fist_left, "position", Vector2(-45.0, -130.0), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		rip_tw.tween_property(fist_right, "position", Vector2(45.0, -130.0), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		rip_tw.tween_property(fist_left, "scale", Vector2(0.65, 0.65), 0.06)
		rip_tw.tween_property(fist_right, "scale", Vector2(0.65, 0.65), 0.06)
		
		# 2. Adım: İki yana şiddetle ayırma (Tear Outward)
		var rip_tw2 = create_tween().set_parallel(true)
		rip_tw2.tween_property(fist_left, "position", Vector2(-340.0, -160.0), 0.12).set_delay(0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		rip_tw2.tween_property(fist_right, "position", Vector2(340.0, -160.0), 0.12).set_delay(0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		rip_tw2.tween_property(fist_left, "rotation", deg_to_rad(-18.0), 0.12).set_delay(0.06)
		rip_tw2.tween_property(fist_right, "rotation", deg_to_rad(18.0), 0.12).set_delay(0.06)
		
		# 3. Adım: Normal hazır duruşa dönüş
		var rip_tw3 = create_tween().set_parallel(true)
		rip_tw3.tween_property(fist_left, "position", fist_left_base_pos, 0.18).set_delay(0.20).set_trans(Tween.TRANS_QUAD)
		rip_tw3.tween_property(fist_right, "position", fist_right_base_pos, 0.18).set_delay(0.20).set_trans(Tween.TRANS_QUAD)
		rip_tw3.tween_property(fist_left, "scale", Vector2(0.52, 0.52), 0.18).set_delay(0.20)
		rip_tw3.tween_property(fist_right, "scale", Vector2(0.52, 0.52), 0.18).set_delay(0.20)
		rip_tw3.tween_property(fist_left, "rotation", 0.0, 0.18).set_delay(0.20)
		rip_tw3.tween_property(fist_right, "rotation", 0.0, 0.18).set_delay(0.20)
	elif hand_sprite and hand_sprite.visible:
		var pt = create_tween().set_parallel(true)
		hand_sprite.scale = base_hand_scale * 1.5
		hand_sprite.position.y = hand_base_pos.y - 40.0
		pt.tween_property(hand_sprite, "scale", base_hand_scale, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pt.tween_property(hand_sprite, "position:y", hand_base_pos.y, 0.25)

	# 2. İkiye Yarma İnfazını Tetikle
	if target.has_method("execute"):
		target.execute()

	current_health = min(max_health, current_health + 25.0)
	_update_hud()
	add_trauma(0.7)
	_apply_hitstop(0.06)
	add_style_points(50.0, "PAPER SHREDDER")
	SoundFX.play_sound("finisher", 3.5)

	# İnfaz kan sıçraması (Splatter Flash)
	if splatter_overlay:
		var stw = create_tween()
		splatter_overlay.color = Color(0.65, 0.05, 0.08, 0.55)
		stw.tween_property(splatter_overlay, "color", Color(0.65, 0.05, 0.08, 0.0), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 3. Akıcı Ağır Çekim (Slow-motion: 0.35 saniye, 0.35x hız)
	_apply_cinematic_slowmo(0.35)

func _apply_cinematic_slowmo(duration_real: float) -> void:
	Engine.time_scale = 0.35
	await get_tree().create_timer(duration_real, true, false, true).timeout
	Engine.time_scale = 1.0



func _check_glory_kill_prompt() -> void:
	if not glory_indicator:
		return
	
	var can_glory_kill = false
	var enemies = get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if e is Node3D and e.get("is_dead") != true and e.get("is_staggered") == true:
			if global_position.distance_to(e.global_position) <= 6.0:
				can_glory_kill = true
				break
	
	glory_indicator.visible = can_glory_kill


# --- Eşya Toplama (Pickups) ---
func collect_pickup(type: int, amount: int) -> bool:
	match type:
		0: # HEALTH
			if current_health >= max_health:
				return false
			current_health = min(max_health, current_health + amount)
			_update_hud()
			SoundFX.play_sound("pickup", 0.0)
			return true
		1: # ARMOR
			if current_armor >= max_armor:
				return false
			current_armor = min(max_armor, current_armor + amount)
			_update_hud()
			SoundFX.play_sound("pickup", 0.0)
			return true
		2: # AMMO
			pistol_reserve = min(180, pistol_reserve + amount)
			shotgun_reserve = min(36, shotgun_reserve + int(amount * 0.2) + 2)
			rocket_reserve = min(12, rocket_reserve + 2)
			_update_hud()
			SoundFX.play_sound("pickup", 0.0)
			return true
		3: # WEAPON_PISTOL
			if not has_pistol:
				has_pistol = true
				pistol_ammo = pistol_max_ammo
				pistol_reserve = max(pistol_reserve, 60)
				_switch_weapon(WeaponType.PISTOL)
				SoundFX.play_sound("finisher", 1.5)
				return true
			return false
		4: # WEAPON_SHOTGUN
			if not has_shotgun:
				has_shotgun = true
				shotgun_ammo = shotgun_max_ammo
				shotgun_reserve = max(shotgun_reserve, 16)
				_switch_weapon(WeaponType.SHOTGUN)
				SoundFX.play_sound("finisher", 2.0)
				return true
			return false
		5: # WEAPON_ROCKET
			if not has_rocket:
				has_rocket = true
				rocket_ammo = rocket_max_ammo
				rocket_reserve = max(rocket_reserve, 6)
				_switch_weapon(WeaponType.ROCKET)
				SoundFX.play_sound("finisher", 2.5)
				return true
			return false
		6: # KEYCARD_YELLOW
			if not has_yellow_key:
				has_yellow_key = true
				if yellow_key_badge:
					yellow_key_badge.visible = true
				SoundFX.play_sound("finisher", 2.5)
				add_style_points(35.0, "KEYCARD FOUND")
				show_objective_notice("SARI KARTON ANAHTARI ALDIN! KUZEY KAPISINA GİT!", Color(1.0, 0.9, 0.2))
				var wm = get_tree().get_first_node_in_group("wave_manager")
				if wm and wm.has_method("on_keycard_collected"):
					wm.on_keycard_collected()
				return true
			return false
	return false

func show_objective_notice(text_msg: String, col: Color = Color(1.0, 0.9, 0.2)) -> void:
	if not objective_notice:
		return
	objective_notice.text = text_msg
	objective_notice.modulate = col
	objective_notice.visible = true
	var tw = create_tween()
	tw.tween_property(objective_notice, "scale", Vector2(1.15, 1.15), 0.1).set_trans(Tween.TRANS_BACK)
	tw.tween_property(objective_notice, "scale", Vector2.ONE, 0.15)

func trigger_victory() -> void:
	if is_level_complete or is_dead:
		return
	is_level_complete = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	velocity = Vector3.ZERO
	SoundFX.play_sound("finisher", 4.0)
	
	var elapsed = (Time.get_ticks_msec() / 1000.0) - level_start_time
	var mins = int(elapsed) / 60
	var secs = int(elapsed) % 60
	var rank_str = style_rank_label.text if style_rank_label else "A - ANARCHY"
	
	if victory_stats:
		victory_stats.text = "GEÇEN SÜRE: %02d:%02d\nSTİL DERECESİ: %s" % [mins, secs, rank_str]
	
	if victory_screen:
		victory_screen.visible = true
		var tw = create_tween()
		victory_screen.modulate.a = 0.0
		tw.tween_property(victory_screen, "modulate:a", 1.0, 0.6)

func show_boss_bar(boss_name: String, current_hp: float, max_hp: float) -> void:
	if boss_bar_container:
		boss_bar_container.visible = true
	if boss_name_label:
		boss_name_label.text = "[ ====== %s ====== ]" % boss_name.to_upper()
	if boss_health_bar:
		boss_health_bar.max_value = max_hp
		boss_health_bar.value = current_hp

func update_boss_hp(current_hp: float) -> void:
	if boss_health_bar:
		boss_health_bar.value = current_hp
	if current_hp <= 0.0 and boss_bar_container:
		boss_bar_container.visible = false

func hide_boss_bar() -> void:
	if boss_bar_container:
		boss_bar_container.visible = false

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO, hit_pos: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return

	if knockback != Vector3.ZERO:
		velocity += knockback * 0.5

	add_trauma(0.4)
	SoundFX.play_sound("enemy_hit", 1.5)

	if current_armor > 0.0:
		var armor_absorbed = amount * 0.65
		if current_armor >= armor_absorbed:
			current_armor -= armor_absorbed
			current_health -= (amount - armor_absorbed)
		else:
			var remaining_damage = amount - current_armor
			current_armor = 0.0
			current_health -= remaining_damage
	else:
		current_health -= amount

	current_health = max(0.0, current_health)
	_update_hud()

	if damage_overlay:
		if damage_overlay_tween and damage_overlay_tween.is_valid():
			damage_overlay_tween.kill()
		damage_overlay_tween = create_tween()
		damage_overlay.color = Color(0.9, 0.1, 0.1, 0.45)
		damage_overlay_tween.tween_property(damage_overlay, "color", Color(0.9, 0.1, 0.1, 0.0), 0.3)

	if hit_pos != Vector3.ZERO and knockback == Vector3.ZERO:
		var push_dir = (global_position - hit_pos).normalized()
		velocity += Vector3(push_dir.x, 0.3, push_dir.z) * 6.0

	if current_health <= 0.0:
		_die()

func _die() -> void:
	is_dead = true
	var death_cam_tween = create_tween()
	death_cam_tween.parallel().tween_property(head, "position:y", 0.3, 0.4)
	death_cam_tween.parallel().tween_property(head, "rotation:z", deg_to_rad(35.0), 0.4)
	
	if death_screen:
		death_screen.visible = true

func _update_hud() -> void:
	if health_label:
		health_label.text = "%d" % int(current_health)
		health_label.modulate = Color(1, 0.4, 0.4, 1) if current_health <= 25.0 else Color.WHITE
	if health_bar:
		health_bar.value = current_health
	if armor_label:
		armor_label.text = "%d" % int(current_armor)
		armor_label.modulate = Color(0.6, 0.85, 1.0, 1.0)
	if armor_bar:
		armor_bar.value = current_armor
	if ammo_label and not is_reloading:
		match current_weapon:
			WeaponType.FISTS:
				ammo_label.text = "∞"
				ammo_label.modulate = Color(0.12, 0.1, 0.08, 1)
			WeaponType.PISTOL:
				ammo_label.text = "%d / %d" % [pistol_ammo, pistol_reserve]
				ammo_label.modulate = Color(0.9, 0.2, 0.2, 1) if pistol_ammo <= 5 else Color(0.12, 0.1, 0.08, 1)
			WeaponType.SHOTGUN:
				ammo_label.text = "%d / %d" % [shotgun_ammo, shotgun_reserve]
				ammo_label.modulate = Color(0.9, 0.2, 0.2, 1) if shotgun_ammo <= 0 else Color(0.12, 0.1, 0.08, 1)
			WeaponType.ROCKET:
				ammo_label.text = "%d / %d" % [rocket_ammo, rocket_reserve]
				ammo_label.modulate = Color(0.9, 0.2, 0.2, 1) if rocket_ammo <= 0 else Color(0.12, 0.1, 0.08, 1)

func _process_normal_movement(delta: float, move_direction: Vector3) -> void:
	var accel = acceleration if is_on_floor() else air_acceleration
	var fric = friction if is_on_floor() else air_friction

	if move_direction.length_squared() > 0.001:
		var target_vel = move_direction * walk_speed
		velocity.x = move_toward(velocity.x, target_vel.x, accel * delta)
		velocity.z = move_toward(velocity.z, target_vel.z, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, fric * delta)
		velocity.z = move_toward(velocity.z, 0.0, fric * delta)

func _update_hand_bobbing(delta: float, speed: float) -> void:
	if is_reloading or is_switching_weapon:
		mouse_input_accum = Vector2.ZERO
		return

	if current_weapon == WeaponType.FISTS:
		if not fist_container or not fist_container.visible:
			return
		# Yumruklar için hafif boksör gardı salınımı
		var sway_x = clamp(-mouse_input_accum.x * 0.35, -20.0, 20.0)
		var sway_y = clamp(-mouse_input_accum.y * 0.25, -15.0, 15.0)
		mouse_input_accum = Vector2.ZERO
		weapon_sway_pos = weapon_sway_pos.lerp(Vector2(sway_x, sway_y), 10.0 * delta)
		
		var bob_y = 0.0
		var bob_x = 0.0
		if speed > 0.5 and is_on_floor() and not is_sliding:
			hand_bob_timer += delta * hand_bob_speed
			bob_y = abs(sin(hand_bob_timer)) * 9.0
			bob_x = sin(hand_bob_timer * 0.5) * 6.0
		else:
			hand_bob_timer = 0.0
			
		var target_left = fist_left_base_pos + weapon_sway_pos + Vector2(bob_x, bob_y)
		var target_right = fist_right_base_pos + weapon_sway_pos + Vector2(bob_x, -bob_y * 0.6)
		if fist_left and not (fist_tween_left and fist_tween_left.is_running()):
			fist_left.position = fist_left.position.lerp(target_left, 12.0 * delta)
		if fist_right and not (fist_tween_right and fist_tween_right.is_running()):
			fist_right.position = fist_right.position.lerp(target_right, 12.0 * delta)
		return

	if not hand_sprite or (hand_tween and hand_tween.is_running()):
		mouse_input_accum = Vector2.ZERO
		return

	# 1. Silah Eylemsizliği & Fare Salınımı (Weapon Sway & Tilt)
	var sway_target_x = clamp(-mouse_input_accum.x * 0.45, -28.0, 28.0)
	var sway_target_y = clamp(-mouse_input_accum.y * 0.35, -20.0, 20.0)
	var sway_target_rot = clamp(-mouse_input_accum.x * 0.0018, -0.12, 0.12)
	mouse_input_accum = Vector2.ZERO # Birikimi tüket

	weapon_sway_pos.x = lerp(weapon_sway_pos.x, sway_target_x, 10.0 * delta)
	weapon_sway_pos.y = lerp(weapon_sway_pos.y, sway_target_y, 10.0 * delta)
	weapon_sway_rot = lerp_angle(weapon_sway_rot, sway_target_rot, 12.0 * delta)
	hand_sprite.rotation = weapon_sway_rot

	# 2. Yere iniş yaylanması (Landing dip)
	landing_impact = move_toward(landing_impact, 0.0, 45.0 * delta)

	# 3. Yürüme Bobbing'i
	var target_pos = hand_base_pos + weapon_sway_pos
	target_pos.y += landing_impact

	if speed > 0.5 and is_on_floor() and not is_sliding:
		hand_bob_timer += delta * hand_bob_speed
		var offset_x = sin(hand_bob_timer * 0.5) * hand_bob_amount_x
		var offset_y = abs(sin(hand_bob_timer)) * hand_bob_amount_y
		target_pos.x += offset_x
		target_pos.y += offset_y
		hand_sprite.position = hand_sprite.position.lerp(target_pos, 14.0 * delta)
	elif is_sliding:
		target_pos.x += 12.0
		target_pos.y += 38.0
		hand_sprite.position = hand_sprite.position.lerp(target_pos, 10.0 * delta)
	else:
		hand_bob_timer = 0.0
		hand_sprite.position = hand_sprite.position.lerp(target_pos, 10.0 * delta)


func _start_dash(move_direction: Vector3) -> void:
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	SoundFX.play_sound("dash", 0.0)
	
	if move_direction.length_squared() > 0.001:
		dash_direction = move_direction
	else:
		dash_direction = -transform.basis.z
	
	velocity = dash_direction * dash_speed
	velocity.y = 0.0

func _process_dash(delta: float) -> void:
	dash_timer -= delta
	velocity = dash_direction * dash_speed
	velocity.y = 0.0
	
	if dash_timer <= 0.0:
		is_dashing = false
		velocity = dash_direction * walk_speed

func _start_slide(move_direction: Vector3) -> void:
	is_sliding = true
	slide_timer = 0.0
	var current_h_vel = Vector3(velocity.x, 0, velocity.z)
	if current_h_vel.length() > 1.0:
		slide_direction = current_h_vel.normalized()
	elif move_direction.length_squared() > 0.001:
		slide_direction = move_direction.normalized()
	else:
		slide_direction = -transform.basis.z
	
	var initial_speed = max(current_h_vel.length() * 1.1, slide_initial_boost)
	velocity.x = slide_direction.x * initial_speed
	velocity.z = slide_direction.z * initial_speed

	_set_crouch_height(true)
	SoundFX.play_sound("dash", -4.0)

func _process_slide(delta: float) -> void:
	slide_timer += delta
	var h_vel = Vector3(velocity.x, 0, velocity.z)
	var new_speed = move_toward(h_vel.length(), 0.0, slide_friction * delta)
	
	if (slide_timer >= slide_max_duration or new_speed < slide_min_speed) and not ceiling_check.is_colliding():
		_stop_slide()
		return
		
	if h_vel.length() > 0.001:
		slide_direction = h_vel.normalized()
	velocity.x = slide_direction.x * new_speed
	velocity.z = slide_direction.z * new_speed

func _stop_slide() -> void:
	is_sliding = false
	slide_cooldown_timer = slide_cooldown
	_set_crouch_height(false)

func _set_crouch_height(crouched: bool) -> void:
	var shape = collision_shape.shape as CapsuleShape3D
	if shape:
		shape.height = sliding_capsule_height if crouched else standing_capsule_height
		collision_shape.position.y = 0.5 if crouched else 1.0

func _update_camera_effects(delta: float) -> void:
	var target_head_y = sliding_head_y if is_sliding else normal_head_y
	head.position.y = lerp(head.position.y, target_head_y, 14.0 * delta)
	
	var target_fov = normal_fov + fov_kick
	fov_kick = move_toward(fov_kick, 0.0, 35.0 * delta)
	if is_dashing:
		target_fov = dash_fov
	elif is_sliding:
		target_fov = slide_fov
	camera.fov = lerp(camera.fov, target_fov, 14.0 * delta)

	# Kamera Sarsıntısı (Trauma Shake) ve Strafe Eğimi (Camera Roll)
	var base_roll = lerp_angle(camera.rotation.z, target_cam_roll, 8.0 * delta)
	if trauma > 0.0:
		trauma = max(0.0, trauma - delta * 1.8)
		var shake = trauma * trauma # Kuadratik düşüş
		camera.h_offset = (randf() * 2.0 - 1.0) * max_shake_offset * shake
		camera.v_offset = (randf() * 2.0 - 1.0) * max_shake_offset * shake
		camera.rotation.z = base_roll + (randf() * 2.0 - 1.0) * max_shake_roll * shake
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0
		camera.rotation.z = base_roll


func _apply_hitstop(duration: float) -> void:
	Engine.time_scale = 0.08
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

func _setup_default_inputs() -> void:
	var actions = {
		"move_forward": KEY_W,
		"move_backward": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"jump": KEY_SPACE,
		"dash": KEY_SHIFT,
		"slide": KEY_CTRL,
		"reload": KEY_R,
		"finisher": KEY_V,
		"berserk": KEY_B,
		"weapon_1": KEY_1,
		"weapon_2": KEY_2,
		"weapon_3": KEY_3,
		"weapon_4": KEY_4
	}
	for action in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var ev = InputEventKey.new()
			ev.physical_keycode = actions[action]
			InputMap.action_add_event(action, ev)
			
	if not InputMap.has_action("shoot"):
		InputMap.add_action("shoot")
		var mouse_ev = InputEventMouseButton.new()
		mouse_ev.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("shoot", mouse_ev)

	if not InputMap.has_action("weapon_next"):
		InputMap.add_action("weapon_next")
		var wheel_ev = InputEventMouseButton.new()
		wheel_ev.button_index = MOUSE_BUTTON_WHEEL_UP
		InputMap.action_add_event("weapon_next", wheel_ev)

# --- Stil ve Kombo Sayacı (Style Meter) ---
func add_style_points(points: float, reason: String = "") -> void:
	style_score = clamp(style_score + points, 0.0, 100.0)
	if style_rank_label:
		var stw = create_tween()
		style_rank_label.scale = Vector2(1.2, 1.2)
		stw.tween_property(style_rank_label, "scale", Vector2.ONE, 0.12)
	_update_style_ui()

func _process_style_meter(delta: float) -> void:
	if style_score > 0.0:
		style_score = max(0.0, style_score - style_decay_rate * delta)
		_update_style_ui()

func _update_style_ui() -> void:
	if not style_rank_label or not style_bar:
		return
	style_bar.value = style_score
	
	if style_score >= 90.0:
		style_rank_label.text = "DEVIL - ULTRAKILL!"
		style_rank_label.modulate = Color(1.0, 0.15, 0.2, 1.0)
	elif style_score >= 70.0:
		style_rank_label.text = "S - SAVAGE!"
		style_rank_label.modulate = Color(1.0, 0.5, 0.1, 1.0)
	elif style_score >= 50.0:
		style_rank_label.text = "A - ANARCHY!"
		style_rank_label.modulate = Color(1.0, 0.9, 0.2, 1.0)
	elif style_score >= 30.0:
		style_rank_label.text = "B - BRUTAL"
		style_rank_label.modulate = Color(0.3, 0.9, 0.4, 1.0)
	elif style_score >= 15.0:
		style_rank_label.text = "C - CARNAGE"
		style_rank_label.modulate = Color(0.3, 0.7, 1.0, 1.0)
	else:
		style_rank_label.text = "D - DESTRUCTION"
		style_rank_label.modulate = Color(0.6, 0.6, 0.7, 1.0)

# --- Berserk Modu (B Tuşu) ---
func _try_activate_berserk() -> void:
	if is_berserk:
		return
	# Aktifleşme şartı: Stil barı S/DEVIL (>= 70) veya can kritik seviyedeyken (<= 30)
	if style_score < 65.0 and current_health > 35.0:
		SoundFX.play_sound("empty", 0.0)
		return

	is_berserk = true
	berserk_timer = berserk_duration
	if berserk_label:
		berserk_label.visible = true
	SoundFX.play_sound("finisher", 3.0)
	add_trauma(0.8)

	# Ekrana Sin City / Çizgi roman siyah-beyaz + kırmızı shader'ı ver
	if retro_filter and retro_filter.material:
		var mat = retro_filter.material as ShaderMaterial
		if mat:
			var tw = create_tween()
			tw.tween_property(mat, "shader_parameter/berserk_blend", 1.0, 0.25)

func _process_berserk(delta: float) -> void:
	if not is_berserk:
		return
	berserk_timer -= delta
	if berserk_label:
		berserk_label.text = "[ BERSERK AKTİF: 2X HASAR! (%.1f sn) ]" % berserk_timer
	if berserk_timer <= 0.0:
		_end_berserk()

func _end_berserk() -> void:
	is_berserk = false
	if berserk_label:
		berserk_label.visible = false
	if retro_filter and retro_filter.material:
		var mat = retro_filter.material as ShaderMaterial
		if mat:
			var tw = create_tween()
			tw.tween_property(mat, "shader_parameter/berserk_blend", 0.0, 0.4)
