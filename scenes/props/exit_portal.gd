extends Area3D
class_name ExitPortal

@onready var sprite: Sprite3D = $Sprite3D
@onready var light: OmniLight3D = $OmniLight3D

var rot_speed: float = 2.4
var is_triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	scale = Vector3(0.01, 0.01, 0.01)
	# Doğuş animasyonu (küçükten büyüme)
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3.ONE, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	if sprite:
		sprite.rotation.z += rot_speed * delta

func _on_body_entered(body: Node3D) -> void:
	if is_triggered:
		return
	if body is Player:
		is_triggered = true
		if body.has_method("trigger_victory"):
			body.trigger_victory()
