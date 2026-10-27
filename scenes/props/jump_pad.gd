extends Area3D

@export var launch_force: float = 20.0
@export var forward_force: float = 12.0
@export var launch_forward: bool = true

@onready var sprite: Sprite3D = $Sprite3D
@onready var light: OmniLight3D = $OmniLight3D

var can_trigger: bool = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not can_trigger:
		return
	if body.is_in_group("player") or body.name == "Player":
		can_trigger = false
		
		# Dikey ve yatay fırlatma kuvveti
		if "velocity" in body:
			body.velocity.y = launch_force
			if launch_forward:
				var fwd = -global_transform.basis.z.normalized()
				# Yatay hızı koruyarak hedefe doğru ekstra itme ver
				body.velocity.x += fwd.x * forward_force
				body.velocity.z += fwd.z * forward_force

		SoundFX.play_sound("jumppad", 3.0)
		
		# Çıkartma Ezilme-Fırlama Animasyonu (Squash & Stretch)
		if sprite:
			var tw = create_tween()
			tw.tween_property(sprite, "scale", Vector3(1.4, 0.4, 1.4), 0.05)
			tw.tween_property(sprite, "scale", Vector3(0.8, 1.6, 0.8), 0.12)
			tw.tween_property(sprite, "scale", Vector3.ONE, 0.15)
			
		# Işık parlaması
		if light:
			var lt = create_tween()
			light.light_energy = 4.0
			lt.tween_property(light, "light_energy", 1.2, 0.3)

		# Kısa bekleme süresi (art arda spam engelleme)
		get_tree().create_timer(0.25).timeout.connect(func(): can_trigger = true)
