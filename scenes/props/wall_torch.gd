extends Node3D
class_name WallTorch

@onready var light: OmniLight3D = $OmniLight3D
@onready var sprite: Sprite3D = $Sprite3D

var base_energy: float = 2.8
var flicker_timer: float = 0.0

func _process(delta: float) -> void:
	flicker_timer += delta * 12.0
	# Meşale ışığı titremesi (Flicker)
	if light:
		var noise = sin(flicker_timer) * 0.15 + cos(flicker_timer * 2.3) * 0.1
		light.light_energy = base_energy + noise
	if sprite:
		sprite.scale.y = 0.42 + sin(flicker_timer * 1.5) * 0.02
