extends Sprite3D
class_name ComicPopup

const TEX_POW = preload("res://assets/Effects/comic_pow.png")
const TEX_BAM = preload("res://assets/Effects/comic_bam.png")
const TEX_BOOM = preload("res://assets/Effects/comic_boom.png")
const TEX_KRAK = preload("res://assets/Effects/comic_krak.png")

static func spawn(parent: Node, spawn_pos: Vector3, type: String = "POW", custom_scale: float = 1.0) -> ComicPopup:
	# Cizgi roman temasi kaldirildi, yalnizca sticker estetigi korundu
	return null

func setup(spawn_pos: Vector3, type: String, custom_scale: float = 1.0) -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	alpha_cut = Sprite3D.ALPHA_CUT_DISCARD
	pixel_size = 0.0016 * custom_scale
	
	match type.to_upper():
		"BAM":
			texture = TEX_BAM
		"BOOM":
			texture = TEX_BOOM
			pixel_size = 0.0022 * custom_scale
		"KRAK":
			texture = TEX_KRAK
			pixel_size = 0.0019 * custom_scale
		_:
			texture = TEX_POW

	global_position = spawn_pos
	rotation.z = deg_to_rad(randf_range(-16.0, 16.0))
	scale = Vector3(0.2, 0.2, 0.2)
	
	# Çizgi roman pop-in ve süzülme animasyonu
	var tw = create_tween()
	# 1. Hızlı fırlama (pop)
	tw.tween_property(self, "scale", Vector3(1.2, 1.2, 1.2), 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector3.ONE, 0.08)
	# 2. Hafif yukarı yükselme
	tw.parallel().tween_property(self, "position:y", position.y + 0.5, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 3. Hızlı küçülerek sönüş
	tw.tween_property(self, "scale", Vector3(0.1, 0.1, 0.1), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.1)
	tw.tween_callback(queue_free)
