extends Area3D
class_name PickupItem

enum PickupType { HEALTH, ARMOR, AMMO, WEAPON_PISTOL, WEAPON_SHOTGUN, WEAPON_ROCKET, KEYCARD_YELLOW }

@export var pickup_type: PickupType = PickupType.HEALTH
@export var amount: int = 25
@export var magnet_speed: float = 12.0
@export var magnet_range: float = 3.5

@export var rotate_speed: float = 3.2
@export var float_amplitude: float = 0.04
@export var is_static_world_item: bool = false
@export var fall_gravity: float = 20.0
@export var stack_count: int = 1

@onready var sprite: Sprite3D = $Sprite3D
@onready var count_label: Label3D = get_node_or_null("CountLabel") as Label3D

var player: Player = null
var hover_timer: float = 0.0
var velocity: Vector3 = Vector3.ZERO
var is_grounded: bool = false
var ground_y: float = 0.35
var base_amount: int = 30
var merge_check_cooldown: float = 0.1
var is_merging: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	hover_timer = randf() * TAU
	base_amount = amount
	_update_stack_display()
	
	if sprite:
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y

	# Eğer dünyada sabit değilse 30 saniyede silinsin ve fırlama ivmesi alsın
	if not is_static_world_item:
		get_tree().create_timer(30.0).timeout.connect(queue_free)
		var angle = randf() * TAU
		var pop_h_speed = randf_range(1.5, 3.5)
		velocity = Vector3(cos(angle) * pop_h_speed, randf_range(3.0, 5.5), sin(angle) * pop_h_speed)
	else:
		velocity = Vector3.ZERO

	# Her halükarda yere düşene kadar fiziksel kontrol açık
	is_grounded = false


func _physics_process(delta: float) -> void:
	hover_timer += delta

	# Fiziksel düşüş ve zemin kontrolü
	if not is_grounded:
		velocity.y -= fall_gravity * delta

		global_position += velocity * delta
		velocity.x = move_toward(velocity.x, 0.0, 3.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 3.0 * delta)

		# Raycast ile zemini bul
		var space_state = get_world_3d().direct_space_state
		var ray_from = global_position + Vector3(0, 0.4, 0)
		var ray_to = global_position + Vector3(0, -0.9, 0)
		var query = PhysicsRayQueryParameters3D.create(ray_from, ray_to)
		query.collision_mask = 1 # Zemin ve statik engeller
		var hit = space_state.intersect_ray(query)

		if hit:
			global_position.y = hit.position.y + 0.35
			is_grounded = true
			velocity = Vector3.ZERO
		elif global_position.y <= 0.35:
			global_position.y = 0.35
			is_grounded = true
			velocity = Vector3.ZERO

	else:
		if sprite:
			sprite.position.y = sin(hover_timer * 2.0) * float_amplitude

		# Yere inen ammo paketleri yakınındaki diğer ammo paketlerini içine çeker
		if pickup_type == PickupType.AMMO and not is_merging:
			merge_check_cooldown -= delta
			if merge_check_cooldown <= 0.0:
				merge_check_cooldown = 0.2
				_check_merge_with_nearby_ammo()

	# Oyuncuya doğru manyetik çekim (Can/Zırh doluysa manyetik çekilmesin)
	if not player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0] as Player

	if player and not player.is_dead:
		var can_collect = true
		if pickup_type == PickupType.HEALTH and player.current_health >= player.max_health:
			can_collect = false
		elif pickup_type == PickupType.ARMOR and player.current_armor >= player.max_armor:
			can_collect = false

		if can_collect:
			var dist = global_position.distance_to(player.global_position)
			if dist <= magnet_range:
				var dir = (player.global_position + Vector3(0, 0.8, 0) - global_position).normalized()
				global_position += dir * magnet_speed * delta

			# Eğer oyuncu önceden temas halinde kaldıysa (canı sonradan azaldıysa) topla
			var overlapping = get_overlapping_bodies()
			for b in overlapping:
				if b is Player and b == player:
					if player.collect_pickup(pickup_type, amount):
						queue_free()
						return

func _check_merge_with_nearby_ammo() -> void:
	var pickups = get_tree().get_nodes_in_group("pickup")
	for p in pickups:
		if p == self or not is_instance_valid(p) or p.get("is_merging") == true:
			continue
		if p.get("pickup_type") == PickupType.AMMO and p.get("is_grounded") == true:
			var d = global_position.distance_to(p.global_position)
			if d <= 1.8: # Birbirine yakın olan mermi kutuları birleşir
				_merge_ammo(p)
				break

func _merge_ammo(other: Node3D) -> void:
	other.set("is_merging", true)
	var other_stacks: int = other.get("stack_count") if other.get("stack_count") else 1
	stack_count += other_stacks
	amount = base_amount * stack_count
	
	# Ortak orta noktaya yumuşakça hareket et
	var mid_pos = (global_position + other.global_position) * 0.5
	global_position = mid_pos
	
	# Hafif büyüme ve parıldama efekti
	if sprite:
		var tw = create_tween()
		var orig_scale = sprite.scale
		sprite.scale = orig_scale * 1.3
		tw.tween_property(sprite, "scale", orig_scale, 0.2)

	_update_stack_display()
	other.queue_free()

func _update_stack_display() -> void:
	if not count_label:
		return
	if stack_count > 1:
		count_label.text = "x%d" % stack_count
		count_label.visible = true
	else:
		count_label.visible = false

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		if body.has_method("collect_pickup"):
			var success = body.collect_pickup(pickup_type, amount)
			if success:
				queue_free()

