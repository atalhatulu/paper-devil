extends StaticBody3D
class_name YellowGate

signal gate_opened

@export var is_open: bool = false
@onready var gate_mesh: CSGBox3D = $GateMesh
@onready var lock_sprite: Sprite3D = $LockSprite
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var trigger_area: Area3D = $TriggerArea
@onready var lock_light: OmniLight3D = $LockLight

var is_opening: bool = false
var prompt_cooldown: float = 0.0

func _ready() -> void:
	if trigger_area:
		trigger_area.body_entered.connect(_on_trigger_body_entered)

func _process(delta: float) -> void:
	if prompt_cooldown > 0.0:
		prompt_cooldown -= delta

func _on_trigger_body_entered(body: Node3D) -> void:
	if is_open or is_opening:
		return
	
	if body is Player:
		if body.has_yellow_key:
			open_gate()
		else:
			if prompt_cooldown <= 0.0:
				prompt_cooldown = 2.0
				SoundFX.play_sound("empty", 2.0)
				body.show_objective_notice("KİLİTLİ! SARI KARTON ANAHTAR GEREKLİ!", Color(1.0, 0.85, 0.2))
				# Kilit parıltısı ve hafif sarsıntı
				if lock_sprite:
					var tw = create_tween()
					tw.tween_property(lock_sprite, "position:x", 0.08, 0.05)
					tw.tween_property(lock_sprite, "position:x", -0.08, 0.05)
					tw.tween_property(lock_sprite, "position:x", 0.0, 0.05)

func open_gate() -> void:
	if is_open or is_opening:
		return
	is_opening = true
	SoundFX.play_sound("finisher", 2.0)

	var p_nodes = get_tree().get_nodes_in_group("player")
	if p_nodes.size() > 0:
		p_nodes[0].show_objective_notice("SARI KAPI AÇILDI! KUZEY PLATFORMUNA İLERLE!", Color(0.3, 1.0, 0.4))

	var tw = create_tween()
	# Kapının yer altına inmesi
	tw.tween_property(self, "position:y", position.y - 5.5, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		is_open = true
		is_opening = false
		if collision_shape:
			collision_shape.disabled = true
		gate_opened.emit()
	)
