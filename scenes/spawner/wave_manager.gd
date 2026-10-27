extends Node3D
class_name WaveManager

# Boomer Shooter Bölüm Yöneticisi (3 Aşamalı Akış: Avlu -> Pusu -> Boss & Çıkış)

enum LevelStage {
	COURTYARD,
	KEYCARD_HUNT,
	AMBUSH,
	NORTH_GATE,
	BOSS_FIGHT,
	PORTAL_OPEN,
	VICTORY
}

var current_stage: LevelStage = LevelStage.COURTYARD

var enemy_scenes = {
	"ground_waddle": preload("res://scenes/enemy/ground/enemy_ground_00.tscn"),
	"ground_skitter": preload("res://scenes/enemy/ground/enemy_ground_01.tscn"),
	"ground_hopper": preload("res://scenes/enemy/ground/enemy_ground_02.tscn"),
	"ground_tank": preload("res://scenes/enemy/ground/enemy_ground_03.tscn"),
	"ground_frost_golem": preload("res://scenes/enemy/ground/enemy_frost_golem.tscn"),
	"ground_werewolf": preload("res://scenes/enemy/ground/enemy_werewolf.tscn"),
	"fly_shooter": preload("res://scenes/enemy/flying/enemy_flying_01.tscn"),
	"fly_hunter": preload("res://scenes/enemy/flying/enemy_flying_02.tscn")
}

const EXIT_PORTAL_SCENE = preload("res://scenes/props/exit_portal.tscn")

var player: Player = null
var active_boss: Node3D = null
var wave_label: Label = null
var stage_initialized: bool = false
var enemies_to_spawn: Array[PackedScene] = []
var spawn_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("wave_manager")
	_find_player()

func _find_player() -> void:
	var p_nodes = get_tree().get_nodes_in_group("player")
	if p_nodes.size() > 0:
		player = p_nodes[0] as Player
		_create_objective_ui()

func _physics_process(delta: float) -> void:
	if not player:
		_find_player()
		return
	if player.is_dead or player.is_level_complete:
		return

	# Kuyrukta spawn bekleyen düşmanlar varsa aralıklarla spawn et
	if enemies_to_spawn.size() > 0:
		spawn_cooldown -= delta
		if spawn_cooldown <= 0.0:
			spawn_cooldown = randf_range(0.3, 0.7)
			var sc = enemies_to_spawn.pop_front()
			_spawn_enemy(sc)

	var alive_count = _get_alive_enemy_count()

	match current_stage:
		LevelStage.COURTYARD:
			if not stage_initialized:
				stage_initialized = true
				_set_objective("HEDEF: Avlu Düşmanlarını Temizle!", Color(1.0, 0.4, 0.2))
			elif alive_count == 0 and enemies_to_spawn.is_empty():
				current_stage = LevelStage.KEYCARD_HUNT
				stage_initialized = false
				SoundFX.play_sound("pickup", 2.0)

		LevelStage.KEYCARD_HUNT:
			if not stage_initialized:
				stage_initialized = true
				_set_objective("GÖREV: Batı Tünelini ve Rampayı Araştır, Sarı Kartı Bul!", Color(1.0, 0.85, 0.2))

		LevelStage.AMBUSH:
			if alive_count == 0 and enemies_to_spawn.is_empty():
				current_stage = LevelStage.NORTH_GATE
				stage_initialized = false
				SoundFX.play_sound("pickup", 2.0)
			else:
				_update_objective_count("TUZAK! Geri Dönüşü Temizle! (%d Düşman Kaldı)" % alive_count)

		LevelStage.NORTH_GATE:
			if not stage_initialized:
				stage_initialized = true
				_set_objective("YOL AÇIK: Kuzey Kapısına İlerle ve Sarı Kilidi Aç!", Color(0.3, 1.0, 0.4))

		LevelStage.BOSS_FIGHT:
			if is_instance_valid(active_boss):
				var boss_hp = active_boss.get("current_health")
				if boss_hp != null:
					player.update_boss_hp(float(boss_hp))
			
			if alive_count == 0 and enemies_to_spawn.is_empty():
				current_stage = LevelStage.PORTAL_OPEN
				_trigger_portal_spawn()
			else:
				_update_objective_count("BÖLÜM SONU: Kağıt Golem'i Yok Et! (%d Düşman)" % alive_count)

func on_keycard_collected() -> void:
	if current_stage == LevelStage.KEYCARD_HUNT or current_stage == LevelStage.COURTYARD:
		current_stage = LevelStage.AMBUSH
		stage_initialized = false
		SoundFX.play_sound("finisher", 2.5)
		_set_objective("TUZAK! Batı Tüneli Çıkışında Pusu Kuruldu!", Color(1.0, 0.2, 0.2))
		
		# Pusu düşmanlarını kuyruğa ekle
		enemies_to_spawn.append(enemy_scenes["ground_werewolf"])
		enemies_to_spawn.append(enemy_scenes["ground_werewolf"])
		enemies_to_spawn.append(enemy_scenes["ground_skitter"])
		enemies_to_spawn.append(enemy_scenes["ground_skitter"])
		enemies_to_spawn.append(enemy_scenes["ground_hopper"])

func on_north_arena_entered() -> void:
	if current_stage == LevelStage.NORTH_GATE or current_stage == LevelStage.AMBUSH or current_stage == LevelStage.KEYCARD_HUNT:
		current_stage = LevelStage.BOSS_FIGHT
		stage_initialized = false
		SoundFX.play_sound("finisher", 3.0)
		_set_objective("BÖLÜM SONU: Karton Buz Golemi ve Muhafızlar Uyandı!", Color(1.0, 0.2, 0.2))

		# Boss Wave: 1 Golem + 2 Werewolves + 2 Hunters
		_spawn_boss_wave()

func _spawn_boss_wave() -> void:
	# Frost Golem (Mini-Boss)
	var golem = enemy_scenes["ground_frost_golem"].instantiate() as Node3D
	get_parent().add_child(golem)
	golem.global_position = Vector3(0, 4.5, -30)
	golem.set("is_alerted", true)
	active_boss = golem
	player.show_boss_bar("KARTON BUZ GOLEMİ", 400.0, 400.0)

	# Muhafızlar
	enemies_to_spawn.append(enemy_scenes["ground_werewolf"])
	enemies_to_spawn.append(enemy_scenes["ground_werewolf"])
	enemies_to_spawn.append(enemy_scenes["fly_hunter"])
	enemies_to_spawn.append(enemy_scenes["fly_hunter"])

func _trigger_portal_spawn() -> void:
	player.hide_boss_bar()
	SoundFX.play_sound("finisher", 4.0)
	_set_objective("ÇIKIŞ PORTALI AÇILDI! Kağıt Cehenneminden Kaç!", Color(0.2, 1.0, 0.6))
	
	if EXIT_PORTAL_SCENE:
		var portal = EXIT_PORTAL_SCENE.instantiate() as Node3D
		get_parent().add_child(portal)
		portal.global_position = Vector3(0, 4.2, -28)

func _get_alive_enemy_count() -> int:
	var living_enemies = get_tree().get_nodes_in_group("enemy")
	var count = 0
	for e in living_enemies:
		if is_instance_valid(e) and e.get("is_dead") != true:
			count += 1
	return count

func _spawn_enemy(scene: PackedScene) -> void:
	if not scene:
		return
	var enemy = scene.instantiate() as Node3D
	get_parent().add_child(enemy)
	
	var is_fly = enemy is FlyingEnemy
	var spawn_pts = []
	var sp_node = get_parent().get_node_or_null("SpawnPoints")
	if sp_node:
		for child in sp_node.get_children():
			if child is Marker3D:
				spawn_pts.append(child.global_position)

	var spawn_base: Vector3
	if spawn_pts.size() > 0:
		spawn_base = spawn_pts.pick_random() + Vector3(randf_range(-2.0, 2.0), 0, randf_range(-2.0, 2.0))
	else:
		var angle = randf() * TAU
		var dist = randf_range(14.0, 24.0)
		spawn_base = player.global_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)

	spawn_base.x = clamp(spawn_base.x, -36.0, 36.0)
	spawn_base.z = clamp(spawn_base.z, -36.0, 36.0)
	if is_fly:
		spawn_base.y += randf_range(3.5, 5.5)

	enemy.global_position = spawn_base
	enemy.set("is_alerted", true)

func _set_objective(text_msg: String, col: Color) -> void:
	if player:
		player.show_objective_notice(text_msg, col)
	if wave_label:
		wave_label.text = text_msg
		wave_label.modulate = col

func _update_objective_count(text_msg: String) -> void:
	if wave_label:
		wave_label.text = text_msg

func _create_objective_ui() -> void:
	var canvas = get_parent().get_node_or_null("UI") as CanvasLayer
	if not canvas:
		return
	wave_label = Label.new()
	wave_label.name = "ObjectiveStatusLabel"
	wave_label.anchors_preset = Control.PRESET_TOP_WIDE
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_label.offset_top = 70.0
	wave_label.offset_bottom = 100.0
	wave_label.add_theme_font_size_override("font_size", 16)
	wave_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	wave_label.add_theme_color_override("font_outline_color", Color.BLACK)
	wave_label.add_theme_constant_override("outline_size", 4)
	canvas.add_child(wave_label)
